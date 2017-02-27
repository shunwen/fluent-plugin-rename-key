# fluent-plugin-rename-key, a plugin for [Fluentd](http://fluentd.org)

## Status
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-rename-key.svg)](https://badge.fury.io/rb/fluent-plugin-rename-key)
[![Build Status](https://travis-ci.org/shunwen/fluent-plugin-rename-key.svg?branch=master)](https://travis-ci.org/shunwen/fluent-plugin-rename-key)
[![Coverage Status](https://coveralls.io/repos/shunwen/fluent-plugin-rename-key/badge.svg?branch=master)](https://coveralls.io/r/shunwen/fluent-plugin-rename-key?branch=master)

## Overview

This manual is for `~> 0.4.0`, which uses fluentd v0.14 API. For earlier version please see [here](https://github.com/shunwen/fluent-plugin-rename-key/tree/fluentd-v0.12).

This plugin renames or replace portion of keys by regular expressions, assign new tags, and re-emits. 

It was created to work around the [field name restrictions](http://docs.mongodb.org/manual/reference/limits/#Restrictions on Field Names) of MongoDB BSON document. Also see [MongoDB Document Types](http://docs.mongodb.org/meta-driver/latest/legacy/bson/#mongodb-document-types) for more information.

## Requirements

For Fluentd earlier than v0.14.0, please use the earlier version 0.3.4. 

| fluent-plugin-rename-key  | Fluentd    | ruby   |
|---------------------------|------------|--------|
| ~> 0.3.4                  | >= v0.12.0 | >= 1.9 |
| ~> 0.4.0                  | >= v0.14.0 | >= 2.1 |

## Installation

See [Fluentd Installation Guide] (http://docs.fluentd.org/v0.12/categories/installation)

## Configuration

### Syntax

```
# <num> is an integer for ordering rules, rules are checked in ascending order. Only the first match is applied.
# <key_regexp> is the regular expression to match keys, ' '(whitespace) is not allowed, use '\s' instead.
# <new_key> is the new key name pattern, MatchData placeholder '${md[1]}' and whitespace are allowed.
rename_rule<num> <key_regexp> <new_key>

# <num> is an integer for ordering rules, rules are checked in ascending order. Only the first match is applied.
# <key_regexp> is the regular expression to match keys, ' '(whitespace) is not allowed, use '\s' instead.
# <new_key> is the pattern to replace the matches with, MatchData placeholder '${md[1]}' and whitespace are allowed. 
#           This field is optional, if missing the matches will be replaced with ''(empty string).
replace_rule<num> <key_regexp> <new_key>

# Optional: dig into the hash structure and rename every matched key, or stop at the first level,
# default is "true"
deep_rename <bool>

# Optional: remove tag prefix. This is only for <match>
remove_tag_prefix <string>

# Optional: append additional name to the original tag, default is 'key_renamed'. This is only for <match>
append_tag <string>
```

### Example

Take this record as example: `'$url' => 'www.google.com', 'level2' => {'$1' => 'option1'}`.
To save it to MongoDB, we can use the following config to replace the keys starting with dollar sign.

For Fluentd v0.14 or later, use `rename_key` filter:

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

The result is `'x$url' => 'www.google.com', 'eve_2' => {'x$1' => 'option1'}`.

### MatchData placeholder

This plugin uses `String#match` to match keys to be replaced. It is possible to reference the resulting `MatchData` in new key names. For example, `${md[0]}` is the matched string, `${md[1]}` is match group 1, and so on. 

**Note:** This is done by matching `${md[0]}` string pattern, so array operations such as range `${md[0..2]}` is not supported.

## Inspired by
This plugin initially resembled the implementation of [fluent-plugin-rewrite-tag-filter](https://github.com/y-ken/fluent-plugin-rewrite-tag-filter).

## Copyright

Copyright :  Copyright (c) 2013- Shunwen Hsiao (@hswtw)
License   :  Apache License, Version 2.0
