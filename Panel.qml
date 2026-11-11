import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "smetak13.babel"

  readonly property string script: Qt.resolvedUrl("bin/babel").toString().replace("file://", "")
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property var texts: ({ cs: "", it: "" })
  property string source: "cs"
  property bool busy: false
  property string error: ""
  property int latestRequest: 0

  function setText(lang, value) {
    if (texts[lang] === value) return
    var next = ({})
    for (var key in texts) next[key] = texts[key]
    next[lang] = value
    texts = next
  }

  function translate(from, text) {
    if (text.trim() === "") return
    latestRequest += 1
    busy = true
    error = ""
    requestComponent.createObject(root, {
      tag: latestRequest,
      original: text,
      command: [script, "translate", Model.instructions(from), Model.replySchema(), text]
    })
  }

  function translateFromSource() {
    translate(source, texts[source])
  }

  function translateText(text) {
    setText("cs", "")
    setText("it", "")
    translate("auto", text)
  }

  function finish(tag, original, stdout) {
    if (tag !== latestRequest) return
    busy = false
    var reply = Model.parseReply(stdout)
    if (reply.error) {
      error = reply.error
      return
    }
    source = reply.source
    setText(reply.source, original)
    setText(Model.targetOf(reply.source), reply.translation)
  }

  function focusSource() {
    var content = panel.loadedContent
    if (content) content.fieldFor(source).forceActiveFocus()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) Qt.callLater(focusSource)

  ShellIpc {
    enabled: root.opened
    target: root.moduleName
    function translateText(text: string): void { root.translateText(text) }
  }

  Component {
    id: requestComponent

    Process {
      id: request
      property int tag: 0
      property string original: ""
      running: true
      stdout: StdioCollector { id: replyOutput; waitForEnd: true }
      onExited: {
        root.finish(request.tag, request.original, String(replyOutput.text || ""))
        request.destroy()
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰗊"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(720))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(420))

    content: FocusScope {
      id: content
      anchors.fill: parent
      implicitHeight: layout.implicitHeight

      function fieldFor(lang) {
        return lang === "cs" ? csColumn.field : itColumn.field
      }

      ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: Style.space(10)

        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: Style.space(10)

          LanguageColumn {
            id: csColumn
            lang: "cs"
            title: "Čeština"
            placeholder: "Napiš česky…"
          }

          PanelActionButton {
            Layout.alignment: Qt.AlignVCenter
            iconText: root.busy ? "󰇘" : (root.source === "cs" ? "󰁔" : "󰁍")
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.heading
            bordered: true
            enabled: !root.busy
            onClicked: root.translateFromSource()
          }

          LanguageColumn {
            id: itColumn
            lang: "it"
            title: "Italiano"
            placeholder: "Scrivi in italiano…"
          }
        }

        Text {
          Layout.fillWidth: true
          textFormat: Text.PlainText
          text: root.error !== "" ? root.error : "Ctrl+Enter"
          color: root.error !== "" ? root.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  component LanguageColumn: ColumnLayout {
    id: column
    property string lang: ""
    property string title: ""
    property string placeholder: ""
    property alias field: area

    readonly property bool active: root.source === lang

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 1
    spacing: Style.spacing.labelGap

    PanelSectionHeader {
      text: column.title
      foreground: column.active ? root.foreground : root.dim
      fontFamily: root.fontFamily
    }

    BorderSurface {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: Style.space(260)
      radius: Style.cornerRadius
      color: Style.controlFill(area.activeFocus, false, root.foreground, Commons.Color.accent)
      borderSpec: Border.controlSpec(area.activeFocus ? "focus" : "normal", root.foreground, Commons.Color.accent)

      ScrollView {
        anchors.fill: parent
        anchors.margins: Style.spacing.controlPaddingX

        TextArea {
          id: area
          text: root.texts[column.lang]
          textFormat: TextEdit.PlainText
          placeholderText: column.placeholder
          placeholderTextColor: root.dim
          wrapMode: TextEdit.Wrap
          color: root.foreground
          selectionColor: Style.selectionFillFor(root.foreground, Commons.Color.accent)
          selectedTextColor: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          background: null
          padding: 0

          onTextChanged: root.setText(column.lang, text)
          onActiveFocusChanged: if (activeFocus) root.source = column.lang

          Keys.onEscapePressed: root.close()
          Keys.onTabPressed: content.fieldFor(Model.targetOf(column.lang)).forceActiveFocus()
          Keys.onReturnPressed: function(event) {
            if (event.modifiers & Qt.ControlModifier) root.translateFromSource()
            else event.accepted = false
          }
          Keys.onEnterPressed: function(event) {
            if (event.modifiers & Qt.ControlModifier) root.translateFromSource()
            else event.accepted = false
          }
        }
      }
    }
  }
}
