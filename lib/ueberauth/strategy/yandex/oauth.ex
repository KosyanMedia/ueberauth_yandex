defmodule Ueberauth.Strategy.Yandex.OAuth do
  @moduledoc """
  OAuth2 for Yandex.

  Add `client_id` and `client_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Yandex.OAuth,
    client_id: System.get_env("YANDEX_APP_ID"),
    client_secret: System.get_env("YANDEX_APP_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
     strategy: __MODULE__,
     site: "https://oauth.yandex.ru",
     authorize_url: "/authorize",
     token_url: "/token"
   ]

  @doc """
  Construct a client for requests to Yandex.

  This will be setup automatically for you in `Ueberauth.Strategy.Yandex`.

  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Yandex.OAuth)

    opts =
      @defaults
      |> Keyword.merge(opts)
      |> Keyword.merge(config)

    OAuth2.Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> put_param("client_id", client().client_id)
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("response_type", "token")
    |> put_param("client_id", client().client_id)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_access_token(params \\ [], opts \\ []) do
    case opts |> client |> OAuth2.Client.get_token(params) do
      {:error, %{body: %{"error" => error, "error_description" => description}}} ->
        {:error, {error, description}}
      {:ok, %{token: %{access_token: nil} = token}} ->
        %{"error" => error, "error_description" => description} = token.other_params
        {:error, {error, description}}
      {:ok, %{token: token}} ->
        {:ok, token}
    end
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("code", params[:code])
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
