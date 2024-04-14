test:
	echo "===> Testing"
	nvim --headless --noplugin -u scripts/tests/minimal.vim \
        -c "PlenaryBustedDirectory tests {minimal_init = 'scripts/tests/minimal.vim'}"
