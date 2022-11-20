from brownie import TokenFarm, DappToken, network, config
from scripts.helpful_scripts import get_account, get_contract
from web3 import Web3


def deploy_token_farm_and_dapp_token():
    KEPT_BALANCE = Web3.toWei(100, "ether")
    account = get_account()
    dapptoken = DappToken.deploy({"from": account})
    tokenfarm = TokenFarm.deploy(
        dapptoken.address,
        {"from": account},
        publish_source=config["networks"][network.show_active()]["verify"],
    )
    tx = dapptoken.transfer(
        tokenfarm.address, dapptoken.totalSupply() - KEPT_BALANCE, {"from": account}
    )
    tx.wait(1)
    wethtoken = get_contract("weth_token")
    fautoken = get_contract("fau_token")
    dict_of_allowed_tokens = {
        dapptoken: get_contract("dai_usd_price_feed"),
        fautoken: get_contract("dai_usd_price_feed"),
        wethtoken: get_contract("eth_usd_price_feed"),
    }
    add_allowed_tokens(tokenfarm, dict_of_allowed_tokens, account)


def add_allowed_tokens(token_farm, dict_of_allowed_tokens, account):
    for token in dict_of_allowed_tokens:
        add_tx = token_farm.addAllowedTokens(token.address, {"from": account})
        add_tx.wait(1)
        set_tx = token_farm.setPriceFeedContract(
            token.address, dict_of_allowed_tokens[token], {"from": account}
        )
        set_tx.wait(1)
    return token_farm


def main():
    deploy_dapptoken_and_tokenfarm()
