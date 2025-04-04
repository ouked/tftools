# tftools

Hacky scripts that may make using terraform easier. Use at your own risk.

## use_local_module.sh

Overwrite references to a remote module to a local version. Useful if developing a module / doing integration testing and using TFE as it uses your developmental version. 

Uncomment the original source / version lines to restore to using the original source.

use `SKIP_INIT=true` to skip initialisation each time.
