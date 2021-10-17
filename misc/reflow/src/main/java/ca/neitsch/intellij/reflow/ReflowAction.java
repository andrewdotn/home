package ca.neitsch.intellij.reflow;

public class ReflowAction
        extends LineSequenceAction
{
    public ReflowAction() {
        super("Reflow Text");
    }

    @Override
    protected String transform(LineSequence ls) {
        return new TextFlow().reflow(ls.getSelectedLines());
    }
}
