# Zsh Config

Somewhat complicated `zsh` configuration scripts, `ruby`/`bash`/`nushell`/`javascript` helpers, and other experiments. The eventual goal is to manage most of this config via `ruby` (formerly `abs` and `lua`).

## Environment

```tree
.
└── archives
└── bin
│   └── bash
│   └── dev
│   └── js
│   └── ruby
│   │   └── functions.rb
│   └── zsh
└── dotbkp
└── plugin
└── settings
└── .zshenv
└── .zshrc
└── functions.json
```

### `.zshrc`

All settings, aliases, plugins, and zsh builtin functions are set in `.zshrc`

User-created functions are stored in `functions.json` and use `bin/ruby/functions.rb` (plus a few helpers in `.zshrc`) to manage functions in my zsh environment. Management includes adding new functions to `functions.json`, serialize a function, verify a functions correctness, etc.

### `.zshenv`

API keys and `$PATH` environment variable are stored in `.zshenv`. This file is generally complete as-is, and is rarely managed.

## History

See [Archive](/archive/) for a full history of settings, scripts, and dsl experiments which ultimately went unused.
