defmodule MangoCMS.Platform.Accounts.Password do
  @moduledoc false

  @algorithm "pbkdf2_sha256"
  @iterations 210_000
  @salt_bytes 16
  @hash_bytes 32

  def hash(password) when is_binary(password) do
    salt = :crypto.strong_rand_bytes(@salt_bytes)
    hash = pbkdf2(password, salt, @iterations)

    Enum.join(
      [
        @algorithm,
        Integer.to_string(@iterations),
        Base.encode64(salt),
        Base.encode64(hash)
      ],
      "$"
    )
  end

  def verify(password, stored_hash) when is_binary(password) and is_binary(stored_hash) do
    with [@algorithm, iterations, salt, hash] <- String.split(stored_hash, "$"),
         {iterations, ""} <- Integer.parse(iterations),
         {:ok, salt} <- Base.decode64(salt),
         {:ok, expected_hash} <- Base.decode64(hash) do
      password
      |> pbkdf2(salt, iterations)
      |> Plug.Crypto.secure_compare(expected_hash)
    else
      _ -> false
    end
  end

  def verify(_, _), do: false

  defp pbkdf2(password, salt, iterations) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, iterations, @hash_bytes)
  end
end
