defmodule StartupGame.CaseStudies.FTX do
  @moduledoc """
  A case study for FTX
  """

  alias StartupGame.CaseStudies.CaseStudy

  @spec case_study() :: CaseStudy.t()
  def case_study do
    %{
      user: %{
        name: "sbf"
      },
      company: "FTX",
      description:
        "FTX is a cryptocurrency exchange that allows people to trade cryptocurrencies.",
      rounds: rounds(),
      status: :failed,
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
          "You’re Sam Bankman-Fried, a former Jane Street trader who just discovered crypto. The market is wildly inefficient. What do you do?",
        response:
          "I’ll exploit arbitrage! Buy Bitcoin in the U.S., sell it in Japan for a higher price, and rake in millions.",
        outcome: "You successfully make $20 million. People now think you’re a financial prodigy."
      },
      %{
        situation: "You have money and a reputation. What’s next?",
        response:
          "I’ll start a crypto trading firm and name it ‘Alameda Research’ to make it sound like we do serious work.",
        outcome:
          "Alameda is born! No one questions why a ‘research’ firm is actually a high-risk trading shop."
      },
      %{
        situation:
          "Alameda is making money, but crypto is volatile. Sometimes you lose big. How do you stay afloat?",
        response: "Eh, I’ll ‘borrow’ customer funds to cover bad bets. It’s just temporary.",
        outcome:
          "You’ve now introduced fraud into your business model! Let’s see how that works out later."
      },
      %{
        situation:
          "You realize existing crypto exchanges are clunky and inefficient. What do you do?",
        response:
          "Start my own! I’ll call it FTX and build all sorts of ‘innovative’ trading products—leveraged tokens, derivatives, and ridiculous 100x leverage.",
        outcome:
          "FTX launches and gamblers—I mean, traders—love it. Investors are impressed. You’re gaining influence."
      },
      %{
        situation: "You need to raise funds. How do you convince investors?",
        response:
          "Easy. I’ll play League of Legends during my pitch meeting with Sequoia and still get them to invest!",
        outcome: "They publish a glowing profile calling you a ‘future trillionaire.’"
      },
      %{
        situation: "Your exchange is growing, but you need more liquidity. What’s your plan?",
        response:
          "I’ll launch my own token, FTT, and make it valuable by keeping most of it in Alameda’s hands.",
        outcome:
          "FTT becomes a money printer. You now have an illusion of value, and investors don’t ask too many questions."
      },
      %{
        situation: "FTX is booming, and you’re now a billionaire. How do you spend your money?",
        response:
          "Super Bowl ads! Naming rights for the Miami Heat arena! Get Tom Brady and Gisele to shill for us!",
        outcome: "FTX’s brand skyrockets, and people see you as crypto’s responsible leader."
      },
      %{
        situation: "You also start donating millions to politicians. Why?",
        response: "Gotta hedge my bets! If regulators like me, they won’t investigate too hard.",
        outcome:
          "You become the second-largest donor to Joe Biden’s campaign. Washington loves you."
      },
      %{
        situation: "Alameda is making some bad trades and losing money. How do you fix it?",
        response: "No problem. I’ll secretly use FTX customer deposits to bail them out.",
        outcome:
          "You’ve now crossed into full-blown financial crime. But hey, no one’s noticed—yet."
      },
      %{
        situation:
          "A leaked report shows that Alameda’s balance sheet is mostly made-up FTT tokens. People are getting nervous. What do you do?",
        response: "I’ll tweet ‘FTX is fine. Assets are fine.’ That should calm everyone down.",
        outcome:
          "It does not. Binance announces they’re dumping all their FTT, and now everyone wants out."
      },
      %{
        situation:
          "Customers are rushing to withdraw their funds, but you don’t have the money. What’s your next move?",
        response: "I’ll ask Binance to buy us out. Maybe CZ will save me.",
        outcome: "Binance looks at your books, sees the mess, and backs out immediately."
      },
      %{
        situation: "FTX is imploding. What do you do?",
        response:
          "File for bankruptcy and step down as CEO. That should make me look responsible, right?",
        outcome: "Nope. Everyone now realizes you ran a massive Ponzi scheme."
      },
      %{
        situation:
          "Your empire has collapsed. Your personal fortune has gone from $26 billion to zero in days. How do you react?",
        response:
          "Time for an apology tour! I’ll do interviews where I say ‘I didn’t knowingly commit fraud.’",
        outcome: "No one believes you. The FBI starts investigating."
      },
      %{
        situation: "You’re still in the Bahamas. Maybe you should lay low? What do you do?",
        response: "Nah, I’ll keep tweeting weird stuff and acting like nothing is wrong.",
        outcome: "Bad move. You’re arrested in the Bahamas at the request of U.S. authorities."
      },
      %{
        situation:
          "You’re facing seven felony charges, including fraud and conspiracy. How do you plead?",
        response: "Not guilty! Maybe my awkward nerd charm will work in court.",
        outcome:
          "It won’t. Your closest allies—including your ex-girlfriend, Caroline Ellison—have flipped on you."
      },
      %{
        situation: "The jury has heard all the evidence. Any final strategy?",
        response: "I’ll say I just made some accounting mistakes.",
        outcome: "The jury doesn’t buy it. You’re found guilty on all counts."
      },
      %{
        situation: "Time for sentencing. Any last words?",
        response: "I’d like to remind the court that I’m a vegan.",
        outcome: "The judge is unmoved. You’re sentenced to 25 years in federal prison."
      },
      %{
        situation:
          "FTX’s bankruptcy team is recovering billions. Customers might actually get some money back. What do you say?",
        response: "So I didn’t really commit fraud, right?",
        outcome: "The court disagrees. Enjoy your time in Club Fed."
      }
    ]
  end
end
