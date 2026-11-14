#!/usr/bin/env bash
cd "$(dirname "$0")"
exec matlab -batch "run('main.m')"
