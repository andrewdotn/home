package ca.neitsch.intellij.reflow;

import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.PlatformDataKeys;
import com.intellij.openapi.application.WriteAction;
import com.intellij.openapi.command.CommandProcessor;
import com.intellij.openapi.editor.Document;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.editor.SelectionModel;
import com.intellij.openapi.project.Project;

public abstract class LineSequenceAction
        extends AnAction
{
    public LineSequenceAction(String s) {
        super(s);
    }


    @Override
    public void actionPerformed(AnActionEvent event) {
        Project p = event.getProject();
        Editor e = event.getData(PlatformDataKeys.EDITOR);
        if (e == null) {
            return;
        }
        Document d = e.getDocument();
        if (d == null) {
            return;
        }
        SelectionModel s = e.getSelectionModel();
        LineSequence ls = new LineSequence(
                new DefaultStringWithSelection(d.getText(),
                        s.getSelectionStart(),
                        s.getSelectionEnd()));

        String replacement = transform(ls);

        CommandProcessor.getInstance().executeCommand(p, () -> {
            WriteAction.run(() ->
                    d.replaceString(
                            ls.getFirstLineStartPos(),
                            ls.getLastLineEndPos(),
                            replacement));
        }, "reflow", d);
    }

    protected abstract String transform(LineSequence ls);
}
