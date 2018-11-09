publish:
	rm -rf _book
	gitbook build
	cp CNAME _book/CNAME
	cp googleb12da88025f54785.html _book/googleb12da88025f54785.html 
	cd _book && git init && git config user.name 'opskumu' && git config user.email 'opskumu@gmail.com' && git add . && git commit -m 'Auto publisher' && git push --force --quiet "git@github.com:opskumu/wiki.git" master:gh-pages > /dev/null 2>&1
	rm -rf _book
