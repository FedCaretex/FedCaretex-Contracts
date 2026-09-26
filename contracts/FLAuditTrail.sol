// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FLAuditTrail
 * @dev Smart Contract untuk mencatat jejak (Audit Trail) dari proses Federated Learning.
 * Menyimpan hash dari update model klien untuk mencegah keracunan data dan menjaga integritas.
 */
contract FLAuditTrail {
    struct ModelUpdate {
        string clientId;
        string roundId;
        string modelHash; // SHA-256 hash dari model weights
        uint256 timestamp;
    }

    // Mapping roundId => list of model updates
    mapping(string => ModelUpdate[]) public roundUpdates;

    event UpdateLogged(string indexed roundId, string indexed clientId, string modelHash, uint256 timestamp);

    /**
     * @dev Fungsi untuk mencatat (log) update model lokal dari aplikasi mobile.
     */
    function logModelUpdate(string memory _clientId, string memory _roundId, string memory _modelHash) public {
        ModelUpdate memory newUpdate = ModelUpdate({
            clientId: _clientId,
            roundId: _roundId,
            modelHash: _modelHash,
            timestamp: block.timestamp
        });

        roundUpdates[_roundId].push(newUpdate);
        
        emit UpdateLogged(_roundId, _clientId, _modelHash, block.timestamp);
    }

    /**
     * @dev Fungsi untuk memverifikasi jumlah update yang masuk pada ronde tertentu.
     */
    function getUpdatesCountByRound(string memory _roundId) public view returns (uint256) {
        return roundUpdates[_roundId].length;
    }
}
