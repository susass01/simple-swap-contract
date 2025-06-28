// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

pragma solidity ^0.8.0;


contract SimpleSwap {
    //Par de tokens con liquidez
    struct Pair {
        uint reserveA;
        uint reserveB;
        mapping(address => uint) liquidity; //Liquidez de cada direccion
        uint totalLiquidity; //Suma total de liquidez del par de tokens
    }

    mapping(bytes32 => Pair) public pairs; //Identificador unico del par

    //Se dispara cuando un usuario agrega liquidez
    event LiquidityAdded(address indexed user, //rastrea que usuario agrego liquidez
                         address tokenA, 
                         address tokenB, 
                         uint amountA, 
                         uint amountB, 
                         uint liquidity);

    //Se dispara cuando un usuario quita liquidez
    event LiquidityRemoved(address indexed user, 
                           address tokenA, 
                           address tokenB, 
                           uint amountA, 
                           uint amountB);

    //Se dispara cuando alguien realiza un swap de tokens                       
    event TokensSwapped(address indexed user, 
                        address tokenIn, 
                        address tokenOut, 
                        uint amountIn, 
                        uint amountOut);

    //Genera la clave unica para identificar el par de tokens
    function _getPairKey(address tokenA, address tokenB) internal pure returns (bytes32) {
        return keccak256( //Genera el hash unico
            abi.encodePacked( //Convierte las direcciones en bloque binario
                            tokenA < tokenB ? tokenA : tokenB, //Comparacion de tokens para garantizar que el menor valor va primero
                            tokenA < tokenB ? tokenB : tokenA
            )
        );
    }

    //Funcion que devuelve las camtidades efectiva que se usaron y la liquidez
    function addLiquidity(
        address tokenA, //Direcciones de tokens
        address tokenB,
        uint amountADesired, //Aporte del token
        uint amountBDesired, 
        uint amountAMin, //Minimo aceptable de Token
        uint amountBMin,
        address to, //Direccion del usuario que recibira los tokens
        uint deadline //Limite de tiempo para que la transaccion sea valida
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(block.timestamp <= deadline, "La Transaccion Expiro"); //Protege al usuario de que la transaccion se realice fuera de tiempo

        bytes32 pairKey = _getPairKey(tokenA, tokenB); //Se genera la clave unica del par de tokens
        Pair storage pair = pairs[pairKey]; //Se accede o se crea el registro del par de tokens

        if (pair.totalLiquidity == 0) { //Si esta vacio se acepta lo que el usuario envia
            amountA = amountADesired;
            amountB = amountBDesired;
        } else { //Si no se calcula cuanto debe aportar
            uint ratioA = (amountADesired * pair.reserveB) / pair.reserveA;
            if (ratioA <= amountBDesired) {
                amountA = amountADesired;
                amountB = ratioA;
            } else {
                uint ratioB = (amountBDesired * pair.reserveA) / pair.reserveB;
                amountA = ratioB;
                amountB = amountBDesired;
            }
        }

        require(amountA >= amountAMin && amountB >= amountBMin, "Cantidades Insuficientes"); //Evita que la operacion se ejecute si cae por debajo

        //Se transfieren los tokens desde la cuenta del usuario al contrato
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        liquidity = amountA + amountB; //Calculo de liquidez agregada
        pair.reserveA += amountA; //Se actualizan las reservas
        pair.reserveB += amountB;
        pair.liquidity[to] += liquidity; //Se registra que el usuario to tiene liquidez
        pair.totalLiquidity += liquidity;

        //Se emite un evento de liquidez agregada
        emit LiquidityAdded(to, tokenA, tokenB, amountA, amountB, liquidity);
    }
    
    //Funcion que permite que el usuario retire su token
    function removeLiquidity(
        address tokenA, //Direccion del Token
        address tokenB,
        uint liquidity, //Liquidez a retirar
        uint amountAMin, //Minima cantidad aceptable
        uint amountBMin,
        address to, //Direccion a la que se enviaran los tokens retirados
        uint deadline //Fecha limite para que la transaccion sea valida
    ) external returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "La Transaccion Expiro"); //Protege al usuario de que la transaccion se ejecute fuera de tiempo

        bytes32 pairKey = _getPairKey(tokenA, tokenB);
        Pair storage pair = pairs[pairKey]; //Localiza al Pair al que pertenece el usuario

        require(pair.liquidity[msg.sender] >= liquidity, "Liquidez Insuficiente"); //Evita que el usuario intente retirar mas de lo que aporto

        //Calcula cuanto le pertenece al usuario segun su liquidez
        amountA = (pair.reserveA * liquidity) / pair.totalLiquidity;
        amountB = (pair.reserveB * liquidity) / pair.totalLiquidity;

        require(amountA >= amountAMin && amountB >= amountBMin, "Diferencia demasiado alta"); //Evita que el usuario reciba menos de lo que espera

        //Se actualizan las variables
        pair.reserveA -= amountA;
        pair.reserveB -= amountB;
        pair.liquidity[msg.sender] -= liquidity;
        pair.totalLiquidity -= liquidity;

        //Devolucion de los tokens
        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        //Se emite un evento donde se notifica el retiro
        emit LiquidityRemoved(to, tokenA, tokenB, amountA, amountB);
    }

    //Funcion de intercambio entre dos tokens
    function swapExactTokensForTokens(
        uint amountIn, //Cantidad de token que el usuario quiere intercambiar
        uint amountOutMin, //Minima cantidad de tokens de salida aceptable
        address[] calldata path, //Arreglo para el token de entrada y el de salida
        address to, //Direccion que recibira lo tokens de salida
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(block.timestamp <= deadline, "La Transaccion Expiro"); //Verifica que la transaccion no se ejecute si expiro el tiempo
        require(path.length == 2, "Solo se permite un unico intercambio"); //Solo permitira hacer un swap de un token a otro

        address tokenIn = path[0];
        address tokenOut = path[1];
        bytes32 pairKey = _getPairKey(tokenIn, tokenOut); //Calculo de la clave unica del par de tokens
        Pair storage pair = pairs[pairKey];

        // Transferir tokens de entrada desde el usuario al contrato
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn); //Se hace la transferencia

        // Obtener cantidad de tokens de salida calculada según reservas
        uint amountOut = getAmountOut(
            amountIn,
            tokenIn < tokenOut ? pair.reserveA : pair.reserveB,
            tokenIn < tokenOut ? pair.reserveB : pair.reserveA
        );

        // Validar que la cantidad de salida no sea menor al mínimo aceptado (slippage)
        require(amountOut >= amountOutMin, "Salida insuficiente");
        
        //Se actualizan las reservas
        if (tokenIn < tokenOut ) {
            pair.reserveA += amountIn;
            pair.reserveB -= amountOut;
        } else {
            pair.reserveB += amountIn;
            pair.reserveA -= amountOut;
        }

        
        IERC20(tokenOut).transfer(to, amountOut); //Se transfieren los tokens de salida al usuario

        
        amounts[0] = amountIn;
        amounts[1] = amountOut;

          //Se emite un evento para visualizar el swap
        emit TokensSwapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        
        
    }

    
    //Funcion para obtener el precio de un token
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        bytes32 pairKey = _getPairKey(tokenA, tokenB); //Clave unica del par de tokens
        Pair storage pair = pairs[pairKey];

        //Determina la reserva que corresponde a cada token
        (uint reserveA, uint reserveB) = tokenA < tokenB 
        ? (pair.reserveA, pair.reserveB) 
        : (pair.reserveB, pair.reserveA);

        require(reserveA > 0 && reserveB > 0, "No hay liquidez"); //Verifica si no hay tokens agregados
        price = (reserveB * 1e18) / reserveA; //Calculo para devolver el precio de 1 unidad de token
    }

    //Funcion para calcular la cantidad de token de salida a recibir
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, "El importe debe ser mayor a 0"); //Valida que el intercambio sea mayor a 0
        require(reserveIn > 0 && reserveOut > 0, "Reservas no validas"); //Valida que haya liquidez suficiente
        uint amountInWithFee = amountIn * 997; //Calculo de la comision
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator; //Calculo del valor del token a recibir por el usuario
    }
}