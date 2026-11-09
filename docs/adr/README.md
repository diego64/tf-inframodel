# Architecture Decision Records

Formato: contexto → decisão → consequências ([Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)).

| ADR | Título | Status |
|---|---|---|
| [0001](0001-nomenclatura.md) | Nomenclatura FAF_<SERVICO> | aceito |
| [0002](0002-nat-instance.md) | NAT instance em vez de NAT Gateway | aceito |
| [0003](0003-single-az.md) | AZ única | aceito |
| [0004](0004-lamp-mysql-local.md) | MySQL local em cada FAF_LAMP | aceito (ressalva) |
| [0005](0005-dns-bind-mais-samba.md) | BIND9 + DNS do Samba | aceito |
| [0006](0006-stacks.md) | Stacks numeradas e um arquivo por recurso | aceito |

Nova decisão: copie o último ADR, incremente o número, status `proposto` até o merge.
