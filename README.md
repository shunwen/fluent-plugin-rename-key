# fluent-plugin-rename-key

## Overview

Fluentd Output filter plugin. It goes through each record, rename keys matching the given regular expressions, and re-emit the event with a new tag. This plugin resembles the implementation of [fluent-plugin-rewrite-tag-filter](https://github.com/y-ken/fluent-plugin-rewrite-tag-filter).

This plugin is created to resolve the invalid record problem while converting to BSON document before inserting to MongoDB, see [restrictions on Field Names](http://docs.mongodb.org/manual/reference/limits/#Restrictions on Field Names) and [MongoDB Document Types](http://docs.mongodb.org/meta-driver/latest/legacy/bson/#mongodb-document-types).

## Installation

install with gem or fluent-gem command as:

```
# for fluentd
$ gem install fluent-plugin-rename-key

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-rename-key
```

## Configuration

### Syntax

```
rename_rule<num> <key_regexp> <new_key>

# Optional: remove tag prefix
remove_tag_prefix <string>

# Optional: append additional name to the original tag, default **key_renamed**
append_tag <string>
```

### Example

Take this record as example: `'$url' => 'www.google.com', 'level2' => {'$1' => 'option1'}`.
To successfully save it into MongoDB, we can use the following config to replace the keys starting with dollar sign.

```
# At rename_rule1, it matches the key starting the `$`, say `$url`, and puts the following characters into match group 1. and uses the content in match group 1, `url`, to generate the new key name `x$url`.

<match input.test>
  type rename_key
  remove_tag_prefix input.test
  append_tag renamed
  rename_rule1 ^\$(.+) x$${md[1]}
  rename_rule2 ^l(eve)l(\d+) ${md[1]}_${md[2]}
</match>
```

The resulting record will be `'x$url' => 'www.google.com', 'eve_2' => {'x$1' => 'option1'}`

### MatchData placeholder

This plugin uses Ruby's `String#match` to match the key to be replaced, and it is possible to refer to the contents of the resulting `MatchData` to create the new key name. `${md[0]}` refers to the matched string and `${md[1]}` refers to match group 1, and so on.

**Note** Range expression ```${md[0..2]}``` is not supported.

## TODO

Pull requests are very welcome!!

## Copyright

Copyright :  Copyright (c) 2013- Shunwen Hsiao (@hswtw)
License   :  Apache License, Version 2.0
