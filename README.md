# Inky Host Dev

A library for allowing developers to simulate the Inky display while working on their host machine. This module implements a HAL (Hardware Abstraction Layer) which is plugged into Inky and it renders pixels using the Erlang WxWidgets library. This avoids additional depedencies.

You can find a sample usage of this module in [pappersversk/sample_inky](https://github.com/pappersverk/sample_inky).

## Minimal usage

Add to deps in mix.exs:
```
..
{:inky_host_dev, "~> 1.0.0", targets: :host, only: :dev},
..
```

Wherever you set up the Inky module in your code:
```
Inky.start_link(:phat, :red, %{
        border: :accent,
        hal_mod: InkyHostDev.HAL
})
```

The [sample project](https://github.com/pappersverk/sample_inky) has a better example where it only set the hal_mod based on target (see the config for host). This would be the preferred way.