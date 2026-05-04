#!/usr/bin/env bash

shellcheck --shell=bash bin/* scripts/*

shfmt --language-dialect bash --diff \
	./**/*
