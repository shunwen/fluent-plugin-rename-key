# fluent-plugin-rename-key, a plugin for [Fluentd](http://fluentd.org)

## Status
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-rename-key.svg)](https://badge.fury.io/rb/fluent-plugin-rename-key)
[![Build Status](https://travis-ci.org/shunwen/fluent-plugin-rename-key.svg?branch=fluentd-v0.12)](https://travis-ci.org/shunwen/fluent-plugin-rename-key)
[![Coverage Status](https://coveralls.io/repos/shunwen/fluent-plugin-rename-key/badge.svg?branch=fluentd-v0.12)](https://coveralls.io/r/shunwen/fluent-plugin-rename-key?branch=fluentd-v0.12)

## Overview

Fluentd filter / output plugin. Renames keys matching the given regular expressions, assign new tags, and re-emits. This plugin resembles the implementation of [fluent-plugin-rewrite-tag-filter](https://github.com/y-ken/fluent-plugin-rewrite-tag-filter).

This plugin is created to resolve the invalid record problem while converting to BSON document before inserting to MongoDB, see [Restrictions on Field Names](http://docs.mongodb.org/manual/reference/limits/#Restrictions on Field Names) and [MongoDB Document Types](http://docs.mongodb.org/meta-driver/latest/legacy/bson/#mongodb-document-types) for more information.

## Installation

Install with gem or fluent-gem command as:

```
# for fluentd
$ gem install fluent-plugin-rename-key

# for td-agent OSX (Homebrew)
$ /usr/local/Cellar/td-agent/1.1.17/bin/fluent-gem install fluent-plugin-rename-key

# for td-agent 2
$ sudo /usr/sbin/td-agent-gem install fluent-plugin-rename-key
```

## Configuration

### Syntax

```
# <num> is an integer, used to sort and apply the rules
# <key_regexp> is the regular expression used to match the keys, whitespace is not allowed, use "\s" instead
# <new_key> is the string with MatchData placeholder for creating the new key name, whitespace is allowed
rename_rule<num> <key_regexp> <new_key>

# <num> is an integer, used to sort and apply the rules
# <key_regexp> is the regular expression used to match the keys, whitespace is not allowed, use "\s" instead
# <new_key> is the string to replace the matches with, with MatchData placeholder for creating the new key name, whitespace is allowed. Optional, if missing then the matches are removed
replace_rule<num> <key_regexp> <new_key>

# Optional: dig into the hash structure and rename every matched key, or rename only keys at the first level,
# default is "true"
deep_rename <bool>

# Optional: remove tag prefix. This is only for <match>
remove_tag_prefix <string>

# Optional: append additional name to the original tag, default is "key_renamed". This is only for <match>
append_tag <string>
```

### Example

Take this record as example: `'$url' => 'www.google.com', 'level2' => {'$1' => 'option1'}`.
To successfully save it into MongoDB, we can use the following config to replace the keys starting with dollar sign.

For fluentd v0.12 or later, use `rename_key` filter:

```
# At rename_rule1, it matches the key starting the '$', say '$url',
# and puts the following characters into match group 1.
# Then uses the content in match group 1, ${md[1]} = 'url', to generate the new key name 'x$url'.

<filter input.test>
  @type rename_key
  rename_rule1 ^\$(.+) x$${md[1]}
  rename_rule2 ^l(.{3})l(\d+) ${md[1]}_${md[2]}
</match>
```

The resulting record is `'x$url' => 'www.google.com', 'eve_2' => {'x$1' => 'option1'}`.
For fluentd v0.10, you need to use output version instead of filter:

```
<match input.test>
  @type rename_key
  remove_tag_prefix input.test
  append_tag renamed
  rename_rule1 ^\$(.+) x$${md[1]}
  rename_rule2 ^l(.{3})l(\d+) ${md[1]}_${md[2]}
</match>
```

The resulting record is `'x$url' => 'www.google.com', 'eve_2' => {'x$1' => 'option1'}` with new tag `renamed`.

### MatchData placeholder

This plugin uses Ruby's `String#match` to match the key to be replaced, and it is possible to refer to the contents of the resulting `MatchData` to create the new key name. `${md[0]}` refers to the matched string and `${md[1]}` refers to match group 1, and so on.

**Note:** Range expression `${md[0..2]}` is not supported.

## TODO

v0.12's filter plugin does not have a functionality to modify tag and time. If you want to modify time in filter plugin, we recommends to migrate to depends on v0.14 Filter Plugin API.
v0.14's filter API has `#filter_with_time` method.

## Copyright

Copyright :  Copyright (c) 2013- Shunwen Hsiao (@hswtw)
License   :  Apache License, Version 2.0

