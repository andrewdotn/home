package ca.neitsch.intellij.reflow;

public interface StringWithSelection {
    String getString();
    int getStartPos();
    int getEndPos();
    String getSelection();
}
