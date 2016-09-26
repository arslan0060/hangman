defmodule Hangman.Game do

  @moduledoc """

  This is the backend for a Hangman game. It manages the game state.
  Clients make moves, and this code validates them and reports back
  the updated state.

  We have a well-defined API that is used by client code

  * `game = Hangman.Game.new_game`

    Set up the state for a new game, and return that state. The client
    applications will pass this state back to your code in all the
    subsequent API calls.

    The state that's returned will at a minimum contain the word to be
    guessed.

    As an aid to testing, there's a second form of this function:

    `game = Hangman.Game.new_game(word)`

    This forces `word` to be this game's hidden word.


  * `len = Hangman.Game.word_length(game)`

    Return the length of the current word.

  * `list = letters_used_so_far(game)`

    The letters that have been guessed so far, returned as a list of
    single character strings. (This includes both correct and
    incorrect guessed.

  * `count = turns_left(game)`

    Returns the number of turns remaining before the game is over.
    For our purposes, a game starts with a generous 10 turns. Each
    _incorrect_ guess decrements this.

  * `word = word_as_string(game, reveal \\ false)`

     Returns the word to be guessed. If the optional second argument is
     false, then any unguessed letters will be returned as underscores.
     If it is true, then the word will be returned complete, showing
     all letters. Letters and underscores are separated by spaces.

  *  `{game, status, guess} = make_move(game, guess)`

     Accept a guess. Return a three element tuple containing the updated
     game state, an atom giving the status at the end of the move, and
     the letter that was guessed.

     The status can be:

     * `:won` — the guess correct and completed the game. The client won

     * `:lost` — the guess was incorrect and the client has run out of
        turns. The game has been lost.

     * `:good_guess` — the guess occurs one or more times in the word

     * `:bad_guess` — the word does not contain the guess. The number
       of turns left has been reduced by 1

## Example of use

Here's this module being exercised from an iex session:

    iex(1)> alias Hangman.Game, as: G
    Hangman.Game

    iex(2)> game = G.new_game
    . . .

    iex(3)> G.word_length(game)
    6

    iex(4)> G.word_as_string_string(game)|
    "_ _ _ _ _ _"

    iex(5)> { game, state, guess } = G.make_move(game, "e")
    . . .

    iex(6)> state
    :good_guess

    iex(7)> G.word_as_string(game)
    "_ _ e e _ e"

    iex(8)> { game, state, guess } = G.make_move(game, "q")
    . . .

    iex(9)> state
    :bad_guess

    iex(10)> { game, state, guess } = G.make_move(game, "r")
    . . .

    iex(11)> state
    :good_guess

    iex(12)> G.word_as_string(game)
    "_ r e e _ e"

    iex(13)> { game, state, guess } = G.make_move(game, "b")
    . . .
    iex(14)> state                                          
    :bad_guess

    iex(15)> { game, state, guess } = G.make_move(game, "f")
    . . .

    iex(16)> state
    :good_guess

    iex(17)> G.word_as_string(game)
    "f r e e _ e"

    iex(18)> { game, state, guess } = G.make_move(game, "z")
    . . .

    iex(19)> state|>IO.inspect
    :won

    iex(20)> G.word_as_string(game)
    "f r e e z e"


    """

    @type state :: map
    @type ch    :: binary
    @type optional_ch :: ch | nil

  @doc """
  Run a game of Hangman with our user. Use the dictionary to
  find a random word, and then let the user make guesses.
  """

  @spec new_game :: state
  defmodule State do
    defstruct turns_left: 10, word: Hangman.Dictionary.random_word(), used_letters: [], correct: %{}
  end

  def new_game, do: %State{}



  @doc """
  This version of `new_game` doesn't look the word up in the
  dictionary. Instead, it is passed as a parameter. This is
  used for testing
  """
  @spec new_game(binary) :: state
  def new_game(word), do: %State{word: word}


  @doc """
  `{game, status, guess} = make_move(game, guess)`

  Accept a guess. Return a three element tuple containing the updated
  game state, an atom giving the status at the end of the move, and
  the letter that was guessed.

  The status can be:

  * `:won` — the guess correct and completed the game. The client won

  * `:lost` — the guess was incorrect and the client has run out of
     turns. The game has been lost.

  * `:good_guess` — the guess occurs one or more times in the word

  * `:bad_guess` — the word does not contain the guess. The number
     of turns left has been reduced by 1
     """

  @spec make_move(state, ch) :: { state, atom, optional_ch }   
  def make_move(state, guess) do
    cond do 
      String.contains?(state.word, guess)->
        new_state=%State{state| used_letters: [guess|state.used_letters], correct: Map.put(state.correct, guess, true)}
        game_correct_status(new_state, guess)
      true->
        new_state=%State{state| turns_left: state.turns_left-1, used_letters: [guess| state.used_letters]}
        game_wrong_status(new_state, guess)
    end
  end

  @doc """
  `len = Hangman.Game.word_length(game)`

  Return the length of the current word.
  """
  @spec word_length(state) :: integer
  def word_length(%{ word: word }), do: String.length(word)
 

  @doc """
  `list = letters_used_so_far(game)`

  The letters that have been guessed so far, returned as a list of
  single character strings. (This includes both correct and
  incorrect guessed.
  """

  @spec letters_used_so_far(state) :: [ binary ]
  def letters_used_so_far(state), do: state.used_letters

  @doc """
  `count = turns_left(game)`

  Returns the number of turns remaining before the game is over.
  For our purposes, a game starts with a generous 10 turns. Each
  _incorrect_ guess decrements this.
  """

  @spec turns_left(state) :: integer
  def turns_left(state), do: state.turns_left

  @doc """
  `word = word_as_string(game, reveal \\ false)`

  Returns the word to be guessed. If the optional second argument is
  false, then any unguessed letters will be returned as underscores.
  If it is true, then the word will be returned complete, showing
  all letters. Letters and underscores are separated by spaces.
  """

  @spec word_as_string(state, boolean) :: binary
  def word_as_string(state, reveal \\ false), do: w_as_s(String.codepoints(state.word), state.correct, reveal) 

  ###########################
  # end of public interface #
  ###########################

  # Your private functions go here
  defp w_as_s([c| rest], correct, false), do: str_replace([c|rest],correct, correct[c])|>Enum.join(" ")|>to_string()
  defp w_as_s(word, _correct, true ),     do: word |>Enum.join(" ")|>to_string()

  defp str_replace([_a, b |rest], correct, nil),   do: ["_"| str_replace([b|rest],correct, correct[b])]
  defp str_replace([a, b |rest], correct, true),   do: [a| str_replace([b|rest],correct, correct[b])]
  defp str_replace([_a], _, nil),                  do: ["_"]
  defp str_replace([a], _, true),                  do: [a]


  defp game_correct_status(state, guess) do
    cond do
      String.contains?(word_as_string(state), "_")->{state, :good_guess, guess}
      true->{state,:won,:nil}
    end
  end

  defp game_wrong_status(%State{turns_left: 0, word: w1, used_letters: used, correct: c}, _guess) do
    {%{turns_left: 0, word: w1, used_letters: used, correct: c}, :lost, nil}
  end
  
  defp game_wrong_status(state, guess), do: {state, :bad_guess, guess}
  
end
