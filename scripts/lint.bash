#!/usr/bin/env bash

shellcheck --shell=bash --external-sources \
	--source-path=lib bin/* \
	lib/*.bash scripts/*

shfmt --language-dialect bash --diff \
	./**/*
