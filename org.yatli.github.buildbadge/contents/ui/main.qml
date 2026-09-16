/*
    SPDX-License-Identifier: MIT
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // ---- configuration (mirrors contents/config/main.xml) ----
    property string repo: Plasmoid.configuration.repo
    property string workflow: Plasmoid.configuration.workflow
    property string branch: Plasmoid.configuration.branch
    property string label: Plasmoid.configuration.label
    property int intervalMinutes: Plasmoid.configuration.intervalMinutes
    property string token: Plasmoid.configuration.token

    // ---- live state ----
    property string state: "unknown"        // success | failure | pending | unknown
    property string statusText: "no status"
    property string statusColor: "#6e7781"
    property string labelColor: "#555555"
    property string defaultBranch: ""
    property string lastUpdated: ""
    property string emptyText: ""
    property string workflowPageUrl: ""
    property var activeXhr: null
    property var recentColors: []

    ListModel { id: runsModel }

    // ---- derived ----
    readonly property string normalizedRepo: {
        var s = repo.trim()
        if (s.length === 0) return ""
        s = s.replace(/^https?:\/\/(www\.)?github\.com\//i, "")
        s = s.replace(/^git@github\.com:/i, "")
        s = s.replace(/^github\.com\//i, "")
        s = s.replace(/\/+$/, "")
        s = s.replace(/\.git$/i, "")
        var parts = s.split("/")
        if (parts.length < 2) return ""
        return parts[0] + "/" + parts[1]
    }

    readonly property string effectiveBranch:
        branch.trim() !== "" ? branch.trim()
        : (defaultBranch !== "" ? defaultBranch : "")

    // Clicking should open the settings dialog when the widget is not usable yet.
    readonly property bool needsConfig: normalizedRepo === "" || statusText === "set token"

    readonly property bool inPanel: [
        PlasmaCore.Types.TopEdge,
        PlasmaCore.Types.RightEdge,
        PlasmaCore.Types.BottomEdge,
        PlasmaCore.Types.LeftEdge,
    ].includes(Plasmoid.location)

    Plasmoid.configurationRequired: normalizedRepo === ""

    Plasmoid.title: normalizedRepo !== "" ? (label + " · " + statusText)
                                          : i18n("GitHub Build Badge")

    toolTipSubText: {
        if (normalizedRepo === "")
            return i18n("Click to configure the repository")
        if (statusText === "set token")
            return i18n("Private repository — click to set your GitHub token")
        var t = normalizedRepo
        if (effectiveBranch !== "") t += "  •  " + effectiveBranch
        if (lastUpdated !== "") t += "  •  " + i18n("updated %1", lastUpdated)
        t += "  •  " + i18n("click for recent runs")
        return t
    }

    // ---- HTTP ----
    Timer {
        id: requestTimeout
        interval: 15000
        repeat: false
        onTriggered: {
            if (root.activeXhr) {
                root.activeXhr.abort()
                root.activeXhr = null
            }
        }
    }

    function httpGet(url, cb) {
        var xhr = new XMLHttpRequest()
        root.activeXhr = xhr
        requestTimeout.restart()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4) return
            requestTimeout.stop()
            if (root.activeXhr === xhr) root.activeXhr = null
            cb(xhr.status, xhr.responseText)
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("Accept", "application/vnd.github+json")
        xhr.setRequestHeader("X-GitHub-Api-Version", "2022-11-28")
        xhr.setRequestHeader("User-Agent", "org.yatli.github.buildbadge")
        if (root.token.length > 0)
            xhr.setRequestHeader("Authorization", "Bearer " + root.token)
        xhr.send()
    }

    // ---- status helpers ----
    function runText(status, conclusion) {
        if (status === "completed") {
            if (conclusion === "success") return "passing"
            if (conclusion === "failure" || conclusion === "timed_out" || conclusion === "startup_failure") return "failing"
            if (conclusion === "cancelled") return "cancelled"
            if (conclusion === "neutral" || conclusion === "skipped") return "skipped"
            if (conclusion === "action_required") return "attention"
            return "no status"
        }
        if (status === "in_progress") return "running"
        if (status === "queued" || status === "waiting" || status === "requested" || status === "pending") return "queued"
        return "no status"
    }

    function runColor(status, conclusion) {
        var t = runText(status, conclusion)
        if (t === "passing") return "#2da44e"
        if (t === "failing") return "#cf222e"
        if (t === "running" || t === "queued" || t === "attention") return "#dbab0a"
        return "#6e7781"
    }

    function runState(status, conclusion) {
        var t = runText(status, conclusion)
        if (t === "passing") return "success"
        if (t === "failing") return "failure"
        if (t === "running" || t === "queued" || t === "attention") return "pending"
        return "unknown"
    }

    function setStatus(st, txt, color) {
        root.state = st
        root.statusText = txt
        root.statusColor = color
    }

    function applyRun(run) {
        setStatus(runState(run.status, run.conclusion),
                  runText(run.status, run.conclusion),
                  runColor(run.status, run.conclusion))
    }

    function formatRelativeTime(iso) {
        if (!iso) return ""
        var t = Date.parse(iso)
        if (isNaN(t)) return ""
        var secs = Math.max(0, Math.floor((Date.now() - t) / 1000))
        if (secs < 60) return i18n("just now")
        var mins = Math.floor(secs / 60)
        if (mins < 60) return i18n("%1m ago", mins)
        var hours = Math.floor(mins / 60)
        if (hours < 24) return i18n("%1h ago", hours)
        var days = Math.floor(hours / 24)
        if (days < 30) return i18n("%1d ago", days)
        return i18n("%1mo ago", Math.floor(days / 30))
    }

    function updateRunsModel(runs) {
        runsModel.clear()
        var colors = []
        for (var i = 0; i < runs.length; i++) {
            var run = runs[i]
            runsModel.append({
                title: run.display_title || run.name || "",
                statusText: runText(run.status, run.conclusion),
                color: runColor(run.status, run.conclusion),
                time: formatRelativeTime(run.created_at),
                url: run.html_url || ""
            })
            colors.push(runColor(run.status, run.conclusion))
        }
        // oldest → newest, so the rightmost dot is the latest run
        root.recentColors = colors.slice().reverse()
        root.emptyText = ""
    }

    // ---- fetching ----
    function fetchRuns(r, b) {
        var wf = workflow.trim()
        var url
        if (wf !== "") {
            url = "https://api.github.com/repos/" + r + "/actions/workflows/" + encodeURIComponent(wf) + "/runs?per_page=10"
        } else {
            url = "https://api.github.com/repos/" + r + "/actions/runs?per_page=10"
        }
        if (b !== "")
            url += "&branch=" + encodeURIComponent(b)

        var shortWf = wf.replace(/^\.github\/workflows\//i, "")
        root.workflowPageUrl = "https://github.com/" + r +
            (wf !== "" ? "/actions/workflows/" + shortWf : "/actions")

        httpGet(url, function (status, body) {
            if (status === 200) {
                try {
                    var j = JSON.parse(body)
                    var runs = j.workflow_runs || []
                    if (runs.length > 0) {
                        applyRun(runs[0])
                        updateRunsModel(runs)
                        root.lastUpdated = Qt.formatTime(new Date(), "HH:mm")
                        return
                    }
                } catch (e) { /* fall through */ }
                runsModel.clear()
                root.emptyText = i18n("No runs found for this workflow.")
                setStatus("unknown", "no runs", "#6e7781")
            } else if (status === 404) {
                runsModel.clear()
                root.emptyText = root.token.length > 0
                    ? i18n("Not found — check the repository and workflow name.")
                    : i18n("Private repository — set a GitHub token to see runs.")
                setStatus("unknown", root.token.length > 0 ? "not found" : "set token", "#6e7781")
            } else if (status === 401 || status === 403) {
                runsModel.clear()
                root.emptyText = i18n("GitHub rejected the token (HTTP %1).", status)
                setStatus("failure", "bad token", "#cf222e")
            } else if (status === 0) {
                runsModel.clear()
                root.emptyText = i18n("Offline — could not reach GitHub.")
                setStatus("unknown", "offline", "#6e7781")
            } else {
                runsModel.clear()
                root.emptyText = i18n("Error fetching runs (HTTP %1).", status)
                setStatus("unknown", "error " + status, "#6e7781")
            }
            root.lastUpdated = Qt.formatTime(new Date(), "HH:mm")
        })
    }

    function ensureBranch(r, cb) {
        if (branch.trim() !== "") { cb(branch.trim()); return }
        if (defaultBranch !== "") { cb(defaultBranch); return }
        httpGet("https://api.github.com/repos/" + r, function (status, body) {
            var b = ""
            if (status === 200) {
                try { b = JSON.parse(body).default_branch || "" } catch (e) {}
            }
            // Only cache a real value; never poison the cache with the
            // "main" fallback, so the true default (e.g. master) is found
            // once a token is set.
            if (b !== "") root.defaultBranch = b
            cb(b !== "" ? b : "main")
        })
    }

    function refresh() {
        var r = normalizedRepo
        if (r === "") {
            setStatus("unknown", "no status", "#6e7781")
            runsModel.clear()
            return
        }
        ensureBranch(r, function (b) { fetchRuns(r, b) })
    }

    // ---- click handling ----
    function openConfig() {
        var a = Plasmoid.action("configure")
        if (a) a.trigger()
    }

    function toggle() {
        if (root.needsConfig) {
            openConfig()
        } else {
            root.expanded = !root.expanded
        }
    }

    // ---- scheduling ----
    Timer {
        id: pollTimer
        interval: Math.max(1, root.intervalMinutes) * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: debounce
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    onRepoChanged: { root.defaultBranch = ""; debounce.restart() }
    onWorkflowChanged: debounce.restart()
    onBranchChanged: debounce.restart()
    onTokenChanged: { root.defaultBranch = ""; debounce.restart() }

    onExpandedChanged: {
        if (root.expanded) root.refresh()
    }

    Component.onCompleted: root.refresh()

    // ---- representations ----
    compactRepresentation: Badge {
        label: root.label
        statusText: root.statusText
        statusColor: root.statusColor
        labelColor: root.labelColor
        recentColors: root.recentColors
        onClicked: root.toggle()
    }

    fullRepresentation: RunsPopup {
        Plasmoid.backgroundHints: root.inPanel ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground
        listModel: runsModel
        repoName: root.normalizedRepo
        openUrl: root.workflowPageUrl
        emptyText: root.emptyText
    }
}
