defmodule StartupGame.CaseStudies.Theranos do
  @moduledoc """
  A case study for Theranos
  """

  alias StartupGame.CaseStudies.CaseStudy

  @spec case_study() :: CaseStudy.t()
  def case_study do
    %{
      user: %{
        name: "eholmes"
      },
      company: "Theranos",
      description:
        "Theranos is a healthcare company that claims to be able to run hundreds of tests from a single drop of blood.",
      rounds: rounds(),
      status: :completed,
      exit_type: :shutdown,
      exit_value: Decimal.new(0),
      founder_return: Decimal.new(0)
    }
  end

  @spec rounds() :: [CaseStudy.round()]
  defp rounds do
    [
      %{
        situation:
          "GM: You’re 19, a Stanford dropout with big dreams and a turtleneck. You’ve just founded Theranos, claiming you can run hundreds of tests from a single drop of blood. Investors love the idea, and you've raised $6 million. Channing Robertson, your Stanford professor, is on board. Your lab is… well, it’s mostly just expensive hopes and dreams.",
        response:
          "Player: Perfect. I’ll double down on secrecy, hype the ‘revolutionary’ nature of our work, and start collecting influential backers. Science? We’ll get to that later.",
        outcome:
          "GM: Congratulations! Investors believe in you more than you believe in your own technology. Your valuation is climbing, and the media is starting to pay attention. No one is asking too many questions… yet."
      },
      %{
        situation:
          "GM: Years pass, and, uh-oh, your technology still doesn’t work. Your employees are frustrated. They keep asking annoying questions like, ‘Shouldn’t we make sure the tests are accurate?’ Instead of addressing this, you hire Sunny Balwani, a former software exec with no medical experience but plenty of cash and aggression. Your internal culture is now based on NDAs, lawsuits, and paranoid secrecy.",
        response:
          "Player: I like the sound of that. Let’s push harder—intimidate employees, fire anyone who doubts me, and keep promising breakthroughs to investors. Fake it till we make it, right?",
        outcome:
          "GM: Absolutely. Morale is plummeting, but the valuation is soaring. You’re up to $1 billion! Employees whisper about fraud, but who listens to scientists anyway?"
      },
      %{
        situation:
          "GM: You’ve gone full tech messiah. You’ve got former U.S. Secretaries of State on your board, Walgreens signs up to roll out your devices, and the media is fawning over you. You’re named the ‘youngest self-made female billionaire.’ One small issue: your technology still doesn’t work.",
        response:
          "Player: Not a problem. I’ll just make sure no one outside Theranos is allowed to test it. Let’s keep the hype machine rolling. Maybe get a few magazine covers?",
        outcome:
          "GM: Done! You’re now on the cover of Forbes, Fortune, and Time. Investors throw more money at you, and your valuation reaches $9 billion. Absolutely no one has tested your device independently. Smooth sailing!"
      },
      %{
        situation:
          "GM: Uh-oh. The media is finally catching on. A pesky journalist at The Wall Street Journal is asking how your machine actually works. Employees are blowing the whistle. Walgreens is getting nervous. The FDA starts sniffing around. Your board tells you to ‘handle it.’",
        response:
          "Player: No worries—I’ll gaslight the media, say it’s all a misunderstanding, and accuse my critics of being jealous men who don’t want to see a woman succeed.",
        outcome:
          "GM: Bold move! But, uh… it’s not working. Walgreens pauses its rollout, the FDA bans your ‘nanotainer’ blood collection device, and regulators are circling like sharks. Might be time for a strategic retreat."
      },
      %{
        situation:
          "GM: Bad news: The SEC is now involved. Investors are suing you. Walgreens has pulled the plug. CMS (the big regulator for medical labs) bans you from operating any lab for two years. Your board members are resigning. Sunny is looking at you nervously.",
        response:
          "Player: Okay, okay. Let’s pivot. I’ll announce that we’re restructuring, cut most of the staff, and quietly try to sell whatever’s left of Theranos. Maybe someone will still buy it?",
        outcome:
          "GM: Nope. It’s over. The SEC charges you and Sunny with ‘massive fraud,’ and by September 2018, Theranos is officially dead. Investors are furious. Employees are relieved. The feds are warming up their handcuffs."
      },
      %{
        situation:
          "GM: Welcome to the boss level: The Trial. Prosecutors say you misled investors, patients, and regulators. You maintain that you were just a misunderstood genius.",
        response:
          "Player: Ugh. Fine. But what if I just… act really sorry and say I was trying to help people?",
        outcome:
          "GM: Nice try. In November 2022, you’re sentenced to 11 years and 3 months in prison. In 2025, the appeals court upholds your conviction. Game over."
      }
    ]
  end
end
