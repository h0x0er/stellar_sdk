defmodule Stellar.Test.Fixtures.XDR.LiquidityPools do
  @moduledoc """
  XDR constructions for LiquidityPools.
  """

  alias StellarBase.XDR.{
    Int64,
    OperationBody,
    Operations.LiquidityPoolWithdraw,
    OperationType,
    PoolID
  }

  @type pool_id :: String.t()
  @type amount :: integer()
  @type price :: float()
  @type xdr :: PoolID.t() | OperationBody.t()

  @spec liquidity_pool_id(pool_id :: pool_id()) :: PoolID.t()
  def liquidity_pool_id("929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072") do
    %PoolID{
      value:
        <<48, 115, 234, 253, 12, 38, 185, 102, 73, 199, 191, 162, 150, 153, 210, 169, 215, 89, 64,
          243, 203, 7, 208, 93, 18, 82, 69, 194, 170, 58, 64, 125>>
    }
  end

  @spec liquidity_pool_withdraw(
          pool_id :: pool_id(),
          amount :: amount(),
          min_amount_a :: amount(),
          min_amount_b :: amount()
        ) :: xdr()
  def liquidity_pool_withdraw(
        "929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
        100,
        20,
        10
      ) do
    %OperationBody{
      operation: %LiquidityPoolWithdraw{
        amount: %Int64{datum: 1_000_000_000},
        min_amount_a: %Int64{datum: 200_000_000},
        min_amount_b: %Int64{datum: 100_000_000},
        pool_id: %PoolID{
          value:
            <<48, 115, 234, 253, 12, 38, 185, 102, 73, 199, 191, 162, 150, 153, 210, 169, 215, 89,
              64, 243, 203, 7, 208, 93, 18, 82, 69, 194, 170, 58, 64, 125>>
        }
      },
      type: %OperationType{identifier: :LIQUIDITY_POOL_WITHDRAW}
    }
  end
end