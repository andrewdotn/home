# Compiling Ruby stores a copy of the exact compiler command-line options
# used to build Ruby in rbconfig.rb. Then Ruby tries to reuse those exact
# command-line options when building extensions.
#
# The intent is to maximize compatibility, but the idea is flawed because
# whether two compilers accept the same command-line options is mostly
# unrelated to whether they produce binary compatible object files. The
# scheme breaks down if you try to use a different but compatible compiler,
# e.g., MinGW vs. MSVC, or if you use a slightly different version of the
# same compiler that accepts slightly different options, e.g. Apple LLVM
# 5.0 vs 5.1 -- see http://stackoverflow.com/q/22312583.
#
# As a workaround, this shim file pretends to be the real rbconfig.rb,
# loads the real one, and updates its values in place.

# Find the first rbconfig.rb on $LOAD_PATH that’s not this file.
$LOAD_PATH.each do |path|
  rbconfig_rb = File.join(path, 'rbconfig.rb')
  if File.exist?(rbconfig_rb) and rbconfig_rb != __FILE__
    require rbconfig_rb
    break
  end
end

module RbConfig
  _bad_options = /-multiply_definedsuppress/

  CONFIG.each { |k, v| CONFIG[k] = v.gsub(_bad_options, '') }
  MAKEFILE_CONFIG.each { |k, v| v.gsub!(_bad_options, '') }
end
