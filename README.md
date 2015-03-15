zbx-cli.rb
===

## Description

Zabbix Command Line Tool

## Features

- Host
 - List
 - Enable/Disable
 - Delete
- Template
 - List
 - Export/Import
- Group
 - List
- Action
 - List
 - Enable/Disable

## Requirement

Zabbix Server > 2.2

## Usage

Set ENV

```bash
export ZBXHOST=127.0.0.1
export ZBXUSER=Admin
export ZBXPASS=zabbix
```

Execute

```
ruby zbx-cli.rb help
```