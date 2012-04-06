# Only useful if you use dropbox to keep this folder in sync between two
# machines
fix-symlinks :
	cd node_modules/.bin && rm -rf * && ln -s ../*/bin/* .
