package ca.neitsch.intellij.reflow.blockcomment;

import java.util.List;

/**
 * A method of marking blocks of text, e.g., C-style /* … comments …  *‌/
 *
 * The lines of text in question are provided to <tt>setBlockToBeDecoded</tt>,
 * which must be the first method called.
 */
public interface Codec {
    /**
     * Set the lines to be decoded.
     *
     * This method should also clear all internal state.
     */
    void setBlockToBeDecoded(List<String> lines);

    /**
     * Return whether this codec applies to the lines.
     */
    boolean detect();

    /**
     * Return the substrings of the lines after stripping comment characters.
     */
    List<String> innerContents();

    /**
     * Re-apply the comment characters to a modified set of lines.
     */
    List<String> apply(List<String> modifiedLines);

    /**
     * The width, in character columns, that this codec takes up. For example, a
     * portion of a Ruby file with ‘    #’ delimiters has width 5.
     */
    int getWrapWidth(); // This is likely to later become a per-line param
}
