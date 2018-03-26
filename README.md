# ABSX

## DESCRIPTION

The acronym stands for "Actor Based Syntax".

## SYNOPSIS

Run bin/absx to start an object oriented console interface. From there, you would declare commands in "noun/verb" fashion (aka actor/action). For example...

```
absx > console helps
```

The above would display help information in regards to the console actor.

## CREATING ACTORS

To create "objects" (aka actors) on the fly...

```
absx > factory builds str as dicepool
```

We can now call actions on that actor...

```
absx > str rolls d20
```


