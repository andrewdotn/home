package ca.neitsch.intellij.reflow;

import com.google.common.base.Joiner;
import com.google.common.collect.Lists;

import java.util.List;

public class SortAction extends LineSequenceAction {
    public SortAction() {
        super("Sort lines");
    }

    @Override
    protected String transform(LineSequence ls) {
        List<String> lines = Lists.newArrayList(ls.getSelectedLines());
        lines.sort(String::compareTo);
        return Joiner.on("\n").join(lines) + "\n";
    }
}
