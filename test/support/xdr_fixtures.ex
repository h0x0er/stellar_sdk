defmodule Stellar.Test.XDRFixtures do
  @moduledoc """
  Stellar's XDR data for test constructions.
  """
  alias Stellar.KeyPair
  alias Stellar.TxBuild.TransactionSignature
  alias Stellar.TxBuild.Transaction, as: Tx

  alias StellarBase.XDR.{
    AccountID,
    AlphaNum12,
    AlphaNum4,
    Asset,
    Assets,
    AssetCode4,
    AssetCode12,
    AssetType,
    CryptoKeyType,
    DataValue,
    DecoratedSignature,
    EnvelopeType,
    Ext,
    Hash,
    Int32,
    Int64,
    Memo,
    MemoType,
    MuxedAccount,
    OperationType,
    OperationBody,
    Operation,
    Operations,
    OptionalDataValue,
    OptionalMuxedAccount,
    OptionalTimeBounds,
    Price,
    PublicKey,
    PublicKeyType,
    SequenceNumber,
    Signature,
    SignatureHint,
    String28,
    String64,
    Transaction,
    TransactionV1Envelope,
    TransactionEnvelope,
    UInt32,
    UInt64,
    UInt256,
    Void
  }

  alias StellarBase.XDR.Operations.{
    AccountMerge,
    CreateAccount,
    ManageData,
    ManageBuyOffer,
    ManageSellOffer,
    Payment,
    PathPaymentStrictSend,
    PathPaymentStrictReceive
  }

  @type optional_account_id :: String.t() | nil
  @type raw_asset :: atom() | {String.t(), String.t()}

  @unit 10_000_000

  @spec muxed_account_xdr(account_id :: String.t()) :: MuxedAccount.t()
  def muxed_account_xdr(account_id) do
    type = CryptoKeyType.new(:KEY_TYPE_ED25519)

    account_id
    |> KeyPair.raw_ed25519_public_key()
    |> UInt256.new()
    |> MuxedAccount.new(type)
  end

  @spec account_id_xdr(account_id :: String.t()) :: MuxedAccount.t()
  def account_id_xdr(account_id) do
    type = PublicKeyType.new(:PUBLIC_KEY_TYPE_ED25519)

    account_id
    |> KeyPair.raw_ed25519_public_key()
    |> UInt256.new()
    |> PublicKey.new(type)
    |> AccountID.new()
  end

  @spec memo_xdr(type :: atom(), value :: any()) :: Memo.t()
  def memo_xdr(type, value) do
    memo_type = MemoType.new(type)

    value
    |> memo_xdr_value(type)
    |> Memo.new(memo_type)
  end

  @spec transaction_xdr(account_id :: String.t()) :: Transaction.t()
  def transaction_xdr(account_id) do
    muxed_account = muxed_account_xdr(account_id)
    base_fee = UInt32.new(100)
    seq_number = SequenceNumber.new(4_130_487_228_432_385)
    time_bounds = OptionalTimeBounds.new(nil)
    memo_type = MemoType.new(:MEMO_NONE)
    memo = Memo.new(nil, memo_type)
    operations = Operations.new([])

    Transaction.new(
      muxed_account,
      base_fee,
      seq_number,
      time_bounds,
      memo,
      operations,
      Ext.new()
    )
  end

  @spec transaction_envelope_xdr(tx :: Tx.t(), signatures :: list(Signature.t())) ::
          TransactionEnvelope.t()
  def transaction_envelope_xdr(tx, signatures) do
    envelope_type = EnvelopeType.new(:ENVELOPE_TYPE_TX)
    decorated_signatures = TransactionSignature.sign(tx, signatures)

    tx
    |> Tx.to_xdr()
    |> TransactionV1Envelope.new(decorated_signatures)
    |> TransactionEnvelope.new(envelope_type)
  end

  @spec decorated_signature_xdr(raw_secret :: binary(), hint :: binary(), payload :: binary()) ::
          DecoratedSignature.t()
  def decorated_signature_xdr(raw_secret, hint, payload) do
    payload
    |> KeyPair.sign(raw_secret)
    |> decorated_signature_xdr(hint)
  end

  @spec decorated_signature_xdr(raw_secret :: binary(), hint :: binary()) ::
          DecoratedSignature.t()
  def decorated_signature_xdr(raw_secret, hint) do
    signature = Signature.new(raw_secret)

    hint
    |> SignatureHint.new()
    |> DecoratedSignature.new(signature)
  end

  @spec operation_xdr(op_body :: struct(), source_account :: optional_account_id()) ::
          Operation.t()
  def operation_xdr(%OperationBody{} = op_body, source_account \\ nil) do
    account = if is_nil(source_account), do: nil, else: muxed_account_xdr(source_account)
    source_account = OptionalMuxedAccount.new(account)
    Operation.new(op_body, source_account)
  end

  @spec create_account_op_xdr(destination :: String.t(), amount :: non_neg_integer()) ::
          CreateAccount.t()
  def create_account_op_xdr(destination, amount) do
    op_type = OperationType.new(:CREATE_ACCOUNT)
    amount = Int64.new(amount * @unit)

    destination
    |> account_id_xdr()
    |> CreateAccount.new(amount)
    |> OperationBody.new(op_type)
  end

  @spec account_merge_op_xdr(destination :: String.t()) :: AccountMerge.t()
  def account_merge_op_xdr(destination) do
    op_type = OperationType.new(:ACCOUNT_MERGE)

    destination
    |> muxed_account_xdr()
    |> AccountMerge.new()
    |> OperationBody.new(op_type)
  end

  @spec payment_op_xdr(
          destination :: String.t(),
          asset :: raw_asset(),
          amount :: non_neg_integer()
        ) :: Payment.t()
  def payment_op_xdr(destination, asset, amount) do
    op_type = OperationType.new(:PAYMENT)
    amount = Int64.new(amount * @unit)
    asset = build_asset_xdr(asset)

    destination
    |> muxed_account_xdr()
    |> Payment.new(asset, amount)
    |> OperationBody.new(op_type)
  end

  @spec path_payment_strict_send_op_xdr(
          destination :: String.t(),
          send_asset :: raw_asset(),
          send_amount :: non_neg_integer(),
          dest_asset :: raw_asset(),
          dest_min :: non_neg_integer(),
          path :: list(raw_asset())
        ) :: PathPaymentStrictSend.t()
  def path_payment_strict_send_op_xdr(
        destination,
        send_asset,
        send_amount,
        dest_asset,
        dest_min,
        path
      ) do
    op_type = OperationType.new(:PATH_PAYMENT_STRICT_SEND)
    destination = muxed_account_xdr(destination)
    send_asset = build_asset_xdr(send_asset)
    send_amount = Int64.new(send_amount * @unit)
    dest_asset = build_asset_xdr(dest_asset)
    dest_min = Int64.new(dest_min * @unit)
    path = assets_path_xdr(path)

    path_payment =
      PathPaymentStrictSend.new(
        send_asset,
        send_amount,
        destination,
        dest_asset,
        dest_min,
        path
      )

    OperationBody.new(path_payment, op_type)
  end

  @spec path_payment_strict_receive_op_xdr(
          destination :: String.t(),
          send_asset :: raw_asset(),
          send_max :: non_neg_integer(),
          dest_asset :: raw_asset(),
          dest_amount :: non_neg_integer(),
          path :: list(raw_asset())
        ) :: PathPaymentStrictReceive.t()
  def path_payment_strict_receive_op_xdr(
        destination,
        send_asset,
        send_max,
        dest_asset,
        dest_amount,
        path
      ) do
    op_type = OperationType.new(:PATH_PAYMENT_STRICT_RECEIVE)
    destination = muxed_account_xdr(destination)
    send_asset = build_asset_xdr(send_asset)
    send_max = Int64.new(send_max * @unit)
    dest_asset = build_asset_xdr(dest_asset)
    dest_amount = Int64.new(dest_amount * @unit)
    path = assets_path_xdr(path)

    path_payment =
      PathPaymentStrictReceive.new(
        send_asset,
        send_max,
        destination,
        dest_asset,
        dest_amount,
        path
      )

    OperationBody.new(path_payment, op_type)
  end

  @spec manage_sell_offer_op_xdr(
          selling :: raw_asset(),
          buying :: raw_asset(),
          amount :: non_neg_integer(),
          price :: number(),
          offer_id :: non_neg_integer()
        ) :: ManageSellOffer.t()
  def manage_sell_offer_op_xdr(selling, buying, amount, {price_n, price_d}, offer_id) do
    op_type = OperationType.new(:MANAGE_SELL_OFFER)
    selling = build_asset_xdr(selling)
    buying = build_asset_xdr(buying)
    amount = Int64.new(amount * @unit)
    price = Price.new(Int32.new(price_n), Int32.new(price_d))
    offer_id = Int64.new(offer_id)

    manage_sell_offer =
      ManageSellOffer.new(
        selling,
        buying,
        amount,
        price,
        offer_id
      )

    OperationBody.new(manage_sell_offer, op_type)
  end

  @spec manage_buy_offer_op_xdr(
          selling :: raw_asset(),
          buying :: raw_asset(),
          amount :: non_neg_integer(),
          price :: number(),
          offer_id :: non_neg_integer()
        ) :: ManageBuyOffer.t()
  def manage_buy_offer_op_xdr(selling, buying, amount, {price_n, price_d}, offer_id) do
    op_type = OperationType.new(:MANAGE_BUY_OFFER)
    selling = build_asset_xdr(selling)
    buying = build_asset_xdr(buying)
    amount = Int64.new(amount * @unit)
    price = Price.new(Int32.new(price_n), Int32.new(price_d))
    offer_id = Int64.new(offer_id)

    manage_buy_offer =
      ManageBuyOffer.new(
        selling,
        buying,
        amount,
        price,
        offer_id
      )

    OperationBody.new(manage_buy_offer, op_type)
  end

  @spec manage_data_op_xdr(entry_name :: String.t(), entry_value: any()) :: AccountMerge.t()
  def manage_data_op_xdr(entry_name, entry_value) do
    op_type = OperationType.new(:MANAGE_DATA)
    value = if is_nil(entry_value), do: nil, else: DataValue.new(entry_value)
    entry_value_xdr = OptionalDataValue.new(value)

    entry_name
    |> String64.new()
    |> ManageData.new(entry_value_xdr)
    |> OperationBody.new(op_type)
  end

  @spec create_asset_native_xdr() :: Asset.t()
  def create_asset_native_xdr do
    Asset.new(Void.new(), AssetType.new(:ASSET_TYPE_NATIVE))
  end

  @spec create_asset4_xdr(code :: String.t(), issuer :: String.t()) :: Asset.t()
  def create_asset4_xdr(code, issuer) do
    asset_type = AssetType.new(:ASSET_TYPE_CREDIT_ALPHANUM4)
    issuer = account_id_xdr(issuer)

    code
    |> AssetCode4.new()
    |> AlphaNum4.new(issuer)
    |> Asset.new(asset_type)
  end

  @spec create_asset12_xdr(code :: String.t(), issuer :: String.t()) :: Asset.t()
  def create_asset12_xdr(code, issuer) do
    asset_type = AssetType.new(:ASSET_TYPE_CREDIT_ALPHANUM12)
    issuer = account_id_xdr(issuer)

    code
    |> AssetCode12.new()
    |> AlphaNum12.new(issuer)
    |> Asset.new(asset_type)
  end

  @spec assets_path_xdr(assets :: list(raw_asset())) :: list(Asset.t())
  def assets_path_xdr(assets) do
    assets
    |> Enum.map(&build_asset_xdr/1)
    |> Assets.new()
  end

  @spec build_asset_xdr(asset :: any()) :: list(Asset.t())
  defp build_asset_xdr(:native), do: create_asset_native_xdr()

  defp build_asset_xdr({code, issuer}) when byte_size(code) < 5,
    do: create_asset4_xdr(code, issuer)

  defp build_asset_xdr({code, issuer}), do: create_asset12_xdr(code, issuer)

  @spec memo_xdr_value(value :: any(), type :: atom()) :: struct()
  defp memo_xdr_value(_value, :MEMO_NONE), do: nil
  defp memo_xdr_value(value, :MEMO_TEXT), do: String28.new(value)
  defp memo_xdr_value(value, :MEMO_ID), do: UInt64.new(value)
  defp memo_xdr_value(value, :MEMO_HASH), do: Hash.new(value)
  defp memo_xdr_value(value, :MEMO_RETURN), do: Hash.new(value)
end
