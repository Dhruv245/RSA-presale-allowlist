Diffchecker logo
Diffchecker
Text
Images
PDF
Excel
Folders
Features
Desktop
Pricing
Sign in
Create an account
Download Diffchecker Desktop
Saved Diffs
You haven't saved any diffs yet.
Diff history
7 minutes ago
3 minutes ago
a minute ago
Clear
Diff history is cleared on refresh

Regular

Real-time

Split

Unified

Word

Character

Expanded

Collapsed

Tools
284 lines
-
7 Removals
Copy all
291 lines
+
15 Additions
Copy all
            /**		            /**
             * @dev 0x33 is a precalulated value that is the offset of where the		             * @dev 0x33 is a precalulated value that is the offset of where the
             *      signature begins in the metamorphic bytecode.		             *      signature begins in the metamorphic bytecode.
             */		             */
            extcodecopy(_metamorphicContractAddress, modPos, 0x33, sig.length)		            extcodecopy(_metamorphicContractAddress, modPos, 0x33, sig.length)
            /**		            /**
             * @dev callDataSize must be dynamically calculated. It follows the		             * @dev callDataSize must be dynamically calculated. It follows the
             *      previously mentioned memory layout including the length and		             *      previously mentioned memory layout including the length and
             *      value of the sig, exponent and modulus.		             *      value of the sig, exponent and modulus.
             */		             */
            let callDataSize := add(0x80, mul(sig.length, 2))		            let callDataSize := add(0x80, mul(sig.length, 2))
            /**		            /**
             * @dev Call 0x05 precompile (modular exponentation) w/ the following		             * @dev Call 0x05 precompile (modular exponentation) w/ the following
             *      args and revert on failure.		             *      args and revert on failure.
             *		             *
             *      Args:		             *      Args:
             *      gas,		             *      gas,
             *      precomipled contract address,		             *      precomipled contract address,
             *      memory pointer of begin of calldata,		             *      memory pointer of begin of calldata,
             *      size of call data (callDataSize),		             *      size of call data (callDataSize),
             *      pointer for where to copy return,		             *      pointer for where to copy return,
             *      size of return data		             *      size of return data
             */		             */
            if iszero(		            if iszero(
                staticcall(gas(), 0x05, 0x80, callDataSize, 0x80, sig.length)		                staticcall(gas(), 0x05, 0x80, callDataSize, 0x80, sig.length)
            ) {		            ) {
                revert(0, 0)		                revert(0, 0)
            }		            }
            /**		            /**
             * @dev Check all leading 32-byte chunk to ensure values are zeroed out.		             * @dev Check all leading 32-byte chunk to ensure values are zeroed out.
             *      If a valid sig then only the last 20 bytes will contains non-zero bits.		             *      If a valid sig then only the last 20 bytes will contains non-zero bits.
             */		             */
            let chunksToCheck := div(sig.length, 0x20)		            let chunksToCheck := div(sig.length, 0x20)
            for { let i := 1 } lt(i, chunksToCheck) { i := add(i, 1) }		            for { let i := 1 } lt(i, chunksToCheck) { i := add(i, 1) }
            {		            {
                if  mload(add(0x60, mul(i, 0x20)))		                if  mload(add(0x60, mul(i, 0x20)))
                {		                {
                    revert(0, 0)		                    revert(0, 0)
                }   		                }   
            }		            }
            /**		            /**
             * @dev Decoded signature will always be contained in last 32-bytes.		             * @dev Decoded signature will always be contained in last 32-bytes.
             *      If msg.sender == decoded signature then return true, else false.		             *      If msg.sender == decoded signature then return true, else false.
             */		             */
            let decodedSig := mload(add(0x60, sig.length))		            let decodedSig := mload(add(0x60, sig.length))
            if eq(caller(), decodedSig) {		            if eq(caller(), decodedSig) {
                // Return true		                // Return true
                mstore(0x00, 0x01)		                mstore(0x00, 0x01)
                return(0x00, 0x20)		                return(0x00, 0x20)
            }		            }
            // Else Return false		            // Else Return false
            mstore(0x00, 0x00)		            mstore(0x00, 0x00)
            return(0x00, 0x20)		            return(0x00, 0x20)
        }		        }
    }		    }
    modifier onlyOwner() {		    modifier onlyOwner() {
        require(owner == msg.sender);		        require(owner == msg.sender);
        _;		        _;
    }		    }
    /**		    /**
     * @notice 'deployPublicKey' is used in initializing the metamorphic contract that		     * @notice 'deployPublicKey' is used in initializing the metamorphic contract that
     *          stores the RSA modulus, n (public key).		     *          stores the RSA modulus, n (public key).
     *		     *
     * @dev     See Repo README for guide to generating public key via python script.		     * @dev     See Repo README for guide to generating public key via python script.
     *		     *
     * https://github.com/RareSkills/RSA-presale-allowlist		     * https://github.com/RareSkills/RSA-presale-allowlist
     */		     */
    function deployPublicKey(bytes calldata publicKey) external onlyOwner {		    function deployPublicKey(bytes calldata publicKey) external onlyOwner {
        require(publicKey.length == modLength, "incorrect publicKey length");		        require(publicKey.length == modLength, "incorrect publicKey length");
        // contract runtime code length (without modulus) = 51 bytes (0x33)		        // contract runtime code length (without modulus) = 51 bytes (0x33)
        bytes memory contractCode = abi.encodePacked(		        bytes memory contractCode = abi.encodePacked(
            hex"3373",		            hex"3373",
            address(this),		            address(this),
            hex"14601b57fe5b73",		            hex"14601b57fe5b73",
            address(this),		            address(this),
            hex"fffe",		            hex"fffe",
            publicKey		            publicKey
        );		        );
        // Code to be returned from metamorphic init callback. See README for explanation.		        // Code to be returned from metamorphic init callback. See README for explanation.
        currentImplementationCode = contractCode;		        currentImplementationCode = contractCode;
        // Load immutable variables onto the stack.		        // Load immutable variables onto the stack.
        bytes32 metaMorphicInitCode = _metamorphicContractInitializationCode;		        bytes32 metaMorphicInitCode = _metamorphicContractInitializationCode;
        bytes32 _salt = salt;		        bytes32 _salt = salt;
        // Address metamorphic contract will be deployed to.		        // Address metamorphic contract will be deployed to.
        address deployedMetamorphicContract;		        address deployedMetamorphicContract;
        assembly {		        assembly {
            /**		            /**
             * Store metamorphic init code in scratch memory space.		             * Store metamorphic init code in scratch memory space.
             * This is previously dynamically created in constructor (based on public key size		             * This is previously dynamically created in constructor (based on public key size
             * and stored as an immutable variable.		             * and stored as an immutable variable.
             */		             */
            mstore(0x00, metaMorphicInitCode)		            mstore(0x00, metaMorphicInitCode)
            /**		            /**
             * CREATE2 args:		             * CREATE2 args:
             *  value: value in wei to send to the new account,		             *  value: value in wei to send to the new account,
             *  offset: byte offset in the memory in bytes, the initialisation code of the new account,		             *  offset: byte offset in the memory in bytes, the initialisation code of the new account,
             *  size: byte size to copy (size of the initialisation code),		             *  size: byte size to copy (size of the initialisation code),
             *  salt: 32-byte value used to create the new contract at a deterministic address		             *  salt: 32-byte value used to create the new contract at a deterministic address
             */		             */
            deployedMetamorphicContract := create2(		            deployedMetamorphicContract := create2(
                0,		                0,
                0x00,		                0x00,
                0x20, // as init code is stored as bytes32		                0x20, // as init code is stored as bytes32
                _salt		                _salt
            )		            )
        }		        }
        // Ensure metamorphic deployment to address as calculated in constructor.		        // Ensure metamorphic deployment to address as calculated in constructor.
        require(		        require(
            deployedMetamorphicContract == metamorphicContractAddress,		            deployedMetamorphicContract == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract."		            "Failed to deploy the new metamorphic contract."
        );		        );
        emit Metamorphosed(deployedMetamorphicContract);		        emit Metamorphosed(deployedMetamorphicContract);
    }		    }
    /**		    /**
     * @notice 'destroyContract' must be called before redeployment of public		     * @notice 'destroyContract' must be called before redeployment of public
     *          key contract.		     *          key contract.
     *		     *
     * @dev     See Repo README.md process walk-through.		     * @dev     See Repo README.md process walk-through.
     *		     *
     * https://github.com/RareSkills/RSA-presale-allowlist		     * https://github.com/RareSkills/RSA-presale-allowlist
     */		     */
    function destroyContract() external onlyOwner {		    function destroyContract() external onlyOwner {
        (bool success, ) = metamorphicContractAddress.call("");		        (bool success, ) = metamorphicContractAddress.call("");
        require(success);		        require(success);
    }		    }
    /**		    /**
     * @notice 'callback19F236F3' is a critical step in the initialization of a		     * @notice 'callback19F236F3' is a critical step in the initialization of a
     *          metamorphic contract.		     *          metamorphic contract.
     *		     *
     * @dev     The function selector for this is '0x0000000e'		     * @dev     The function selector for this is '0x0000000e'
     */		     */
    function callback19F236F3() external view returns (bytes memory) {		    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;		        return currentImplementationCode;
    }		    }
}		}
Previous
Select a valid section to merge
Next

Editor
Compare & merge
Clear
Export as PDF
Save DiffShare
No file chosen
Original Text
🤝
236
237
238
239
240
241
242
243
244
245
246
247
248
249
250
251
252
253
254
255
256
257
258
259
260
261
262
263
264
265
266
267
268
269
270
271
272
273
274
275
276
277
278
279
280
281
282
283
284
            mstore(0x00, metaMorphicInitCode)

            /**
             * CREATE2 args:
             *  value: value in wei to send to the new account,
             *  offset: byte offset in the memory in bytes, the initialisation code of the new account,
             *  size: byte size to copy (size of the initialisation code),
             *  salt: 32-byte value used to create the new contract at a deterministic address
             */
            deployedMetamorphicContract := create2(
                0,
                0x00,
                0x20, // as init code is stored as bytes32
                _salt
            )
        }

        // Ensure metamorphic deployment to address as calculated in constructor.
        require(
            deployedMetamorphicContract == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract."
        );

        emit Metamorphosed(deployedMetamorphicContract);
    }

    /**
     * @notice 'destroyContract' must be called before redeployment of public
     *          key contract.
     *
     * @dev     See Repo README.md process walk-through.
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function destroyContract() external onlyOwner {
        (bool success, ) = metamorphicContractAddress.call("");
        require(success);
    }

    /**
     * @notice 'callback19F236F3' is a critical step in the initialization of a
     *          metamorphic contract.
     *
     * @dev     The function selector for this is '0x0000000e'
     */
    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;
    }
}
No file chosen
Changed Text
🤝
251
252
253
254
255
256
257
258
259
260
261
262
263
264
265
266
267
268
269
270
271
272
273
274
275
276
277
278
279
280
281
282
283
284
285
286
287
288
289
290
291
            deployedMetamorphicContract := create2(
                0,
                0x00,
                0x20, // as init code is stored as bytes32
                _salt
            )
        }

        // Ensure metamorphic deployment to address as calculated in constructor.
        require(
            deployedMetamorphicContract == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract."
        );

        emit Metamorphosed(deployedMetamorphicContract);
    }

    /**
     * @notice 'destroyContract' must be called before redeployment of public
     *          key contract.
     *
     * @dev     See Repo README.md process walk-through.
     *
     * https://github.com/RareSkills/RSA-presale-allowlist
     */
    function destroyContract() external onlyOwner {
        (bool success, ) = metamorphicContractAddress.call("");
        require(success);
    }

    /**
     * @notice 'callback19F236F3' is a critical step in the initialization of a
     *          metamorphic contract.
     *
     * @dev     The function selector for this is '0x0000000e'
     */
    function callback19F236F3() external view returns (bytes memory) {
        return currentImplementationCode;
    }
}

ad
Diffchecker Desktop
The most secure way to run Diffchecker. Get the Diffchecker Desktop app: your diffs never leave your computer!
GET DESKTOP
ad
Bibcitation
A free online tool to generate citations, reference lists, and bibliographies. APA, MLA, Chicago, and more.
CHECK IT OUT
Find Difference
© 2023 Checker Software Inc.ContactCLITermsPrivacy PolicyAPIOlder Compare Text
EnglishFrançaisEspañolPortuguêsItalianoDeutschहिन्दी简体繁體日本語
