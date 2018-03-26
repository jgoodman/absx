# ABSX

## DESCRIPTION

The acronym stands for "Actor Based Syntax".

## SYNOPSIS

To start an object oriented console interface, run...

```
bin/absx
```

From here, you would declare commands in "noun/verb" fashion (aka actor/action). For example...

```
absx > console helps
```

The above would display help information in regards to the console actor.

## CREATING ACTORS

To create "objects" (aka actors) on the fly...

```
absx > factory builds str as dicepool
```

The above would create an actor with the alias of "str" with "dicepool" as it's class.

With our new actor, we can now call actions on it...

```
absx > str rolls d20
```

You'll begin to notice that actors have state information about them. This can dump this information to the console by running...

```
absx > str confesses
```
