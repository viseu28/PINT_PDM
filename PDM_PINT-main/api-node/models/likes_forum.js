const { INTEGER } = require("sequelize");

module.exports = function (sequelize, DataTypes) {
    return sequelize.define('likes_forum', {
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        idutilizador: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        idpost: {
            type: DataTypes.INTEGER,
            allowNull: true  // Pode ser NULL quando é like de resposta
        },
        idresposta: {
            type: DataTypes.INTEGER,
            allowNull: true  // Pode ser NULL quando é like de post
        },
        tipo: {
            type: DataTypes.STRING(10),
            allowNull: false
        }
    }, {
        tableName: 'likes_forum',
        timestamps: false,
        validate: {
            // Garantir que pelo menos um dos campos está preenchido
            eitherPostOrResponse() {
                if (!this.idpost && !this.idresposta) {
                    throw new Error('Deve especificar idpost OU idresposta');
                }
                if (this.idpost && this.idresposta) {
                    throw new Error('Não pode especificar idpost E idresposta ao mesmo tempo');
                }
            }
        }
    });
};