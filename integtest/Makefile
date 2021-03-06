SHELL = /bin/bash -eux -o pipefail
MAKEFLAGS += --silent

# Used by the test for --all
export GIT_AUTHOR_NAME=Test
export GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test
export GIT_COMMITTER_EMAIL=test@example.com

.PHONY: check
check: \
	style \
	minimal_expected_files minimal_same_files \
	includes_expected_files includes_same_files \
	readme_expected_files readme_same_files \
	small_all_expected_files

.PHONY: style
style: html_diff
	pycodestyle html_diff

define STANDARD_EXPECTED_FILES=
	[ -s $^/index.html ]
	[ -s $^/docs.js ]
	[ -s $^/styles.css ]
	[ -s $^/template.md5 ]
endef

.PHONY: readme_expected_files
readme_expected_files: /tmp/readme_asciidoc
	$(STANDARD_EXPECTED_FILES)
	# Checking for expected html files
	[ -s $^/_conditions_of_use.html ]
	# Checking for copied images
	[ -s $^/resources/cat.jpg ]
	[ -s $^/images/icons/caution.png ]
	[ -s $^/images/icons/important.png ]
	[ -s $^/images/icons/note.png ]
	[ -s $^/images/icons/warning.png ]
	[ -s $^/images/icons/callouts/1.png ]
	[ -s $^/images/icons/callouts/2.png ]
	[ -s $^/snippets/blocks/1.json ]

.PHONY: %_expected_files
%_expected_files: /tmp/%_asciidoc
	$(STANDARD_EXPECTED_FILES)

.PHONY: %_same_files
%_same_files: /tmp/%_asciidoc /tmp/%_asciidoctor
	diff \
		<(cd /tmp/$*_asciidoc    && find * -type f | sort \
			| grep -v snippets/blocks \
		) \
		<(cd /tmp/$*_asciidoctor && find * -type f | sort)
	# The grep -v below are for known issues with asciidoctor
	for file in $$(cd /tmp/$*_asciidoc && find * -type f -name '*.html' \
			| grep -v 'blocks\|changes\|experimental'); do \
		./html_diff /tmp/$*_asciidoc/$$file /tmp/$*_asciidoctor/$$file; \
	done

define BD=
/docs_build/build_docs.pl --in_standard_docker --out $@
endef

/tmp/readme_asciidoc: /docs_build/README.asciidoc
	$(BD) --doc /docs_build/README.asciidoc

/tmp/readme_asciidoctor: /docs_build/README.asciidoc
	$(BD) --asciidoctor --doc /docs_build/README.asciidoc

# These don't declare dependencies because we don't know in general which files
# are needed to build which asciidoc files.
.PRECIOUS: /tmp/%_asciidoc     # don't try to remove the directory. you can't
/tmp/%_asciidoc:
	$(BD) --doc $*.asciidoc

.PRECIOUS: /tmp/%_asciidoctor  # don't try to remove the directory. you can't
/tmp/%_asciidoctor:
	$(BD) --asciidoctor --doc $*.asciidoc

.PHONY: small_all_expected_files
small_all_expected_files: /tmp/small_all
	[ -s $^/html/branches.yaml ]
	grep '<a class="ulink" href="test/current/index.html" target="_top">Test book</a>' $^/html/index.html > /dev/null
	grep '<meta http-equiv="refresh" content="0; url=current/index.html">' $^/html/test/index.html > /dev/null
	[ -s $^/html/test/current/index.html ]

.PRECIOUS: /tmp/small_all
/tmp/small_all:
	# Builds "--all" documentation specified by by the "small_conf.yaml" file.

	# First build a repository to use as the source.
	rm -rf /tmp/source
	git init /tmp/source
	cp minimal.asciidoc /tmp/source/
	cd /tmp/source && \
		git add . && \
		git commit -m 'minimal'

	# Initialize a bare repository that the docs build process can use as a
	# remote. It is used to pushing to github but it can push to a remote on
	# the filesystem just fine.
	git init --bare /tmp/small_all.git

	# Actually build the docs
	/docs_build/build_docs.pl --in_standard_docker --all --push \
		--target_repo /tmp/small_all.git \
		--conf small_conf.yaml

	# Check out the files we just built
	git clone /tmp/small_all.git /tmp/small_all
