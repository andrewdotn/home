package ca.neitsch.intellij.reflow;

import ca.neitsch.intellij.reflow.blockcomment.CComment;
import ca.neitsch.intellij.reflow.blockcomment.Codec;
import ca.neitsch.intellij.reflow.blockcomment.CommonPrefix;
import com.google.common.base.Joiner;

import java.util.Arrays;
import java.util.List;

public class TextFlow {

    /**
     * Return the reflowed text with which to replace the substring of
     * input from startPos to endPos.
     *
     * @param lines A list of strings, without trailing newlines, representing
     *         the lines of text to be reflowed
     * @return The reflowed text, containing newlines including a trailing
     *         newline.
     */
    String reflow(List<String> lines) {
        for (String s: lines) {
          if (s.endsWith("\n")) {
            throw new IllegalArgumentException(
                    String.format("%s ends with newline", s));
          }
        }

        Codec blockCommentCodec = null;
        for (Codec c: new Codec[]{
                new CComment(),
                new CommonPrefix(),
        }) {
            c.setBlockToBeDecoded(lines);
            if (c.detect()) {
                blockCommentCodec = c;
                break;
            }
        }
        if (blockCommentCodec == null) {
            throw new RuntimeException("No block comment codec found");
        }

        StringBuilder sb = new StringBuilder();
        for (String s: blockCommentCodec.innerContents()) {
            sb.append(" ").append(s);
        }
        List<String> balanced = Arrays.asList(
                balance(sb.toString(), 80 - blockCommentCodec.getWrapWidth())
                .split("\n"));

        return Joiner.on("\n").join(blockCommentCodec.apply(balanced)) + "\n";
    }

    /** Reflow prefix-less string S to at most l characters */
    public String balance(String s, int maxWidth) {
        return new GreedyTextFlow(s, maxWidth).getFlowed();
    }
}
