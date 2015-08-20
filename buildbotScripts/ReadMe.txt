Scripts for lldb buildbot builders
===================================

These scripts are called by lldb buildbot steps
Scripts under windowsBatch folder applies to both of linux and darwin builders
Scripts under bashShell folder applies to windows builder

Directory layout:
 $ROOT/buildbotScripts/windowsBatch/svntotbuild - scripts for windows builder to test public svn repo - http://lab.llvm.org:8011/console
 $ROOT/buildbotScripts/windowsBatch/asbuild - scripts for windows builder to test internal builds from as builder
 $ROOT/buildbotScripts/bashShell/svntotbuild - scripts for linux and darwin builders to test public svn repo - http://lab.llvm.org:8011/console
 $ROOT/buildbotScripts/bashshell/asbuild - scripts for linux and darwin builders to test internal builds from as builder
