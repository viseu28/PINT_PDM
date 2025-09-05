const { INTEGER } = require("sequelize");

module.exports = function (sequelize, DataTypes) {
    return sequelize.define('likes_forum', {
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        id_utilizador: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        id_post: {
            type: DataTypes.INTEGER,
            allowNull: true  // Pode ser NULL quando é like de resposta
        },
        idresposta: {
            type: DataTypes.INTEGER,
            allowNull: true  // Pode ser NULL quando é like de post
        },
        data_like: {
            type: DataTypes.DATE,
            allowNull: true
        }
    }, {
        tableName: 'likes_forum',
        timestamps: false,
        validate: {
            // Garantir que pelo menos um dos campos está preenchido
            eitherPostOrResponse() {
                if (!this.id_post && !this.idresposta) {
                    throw new Error('Deve especificar id_post OU idresposta');
                }
                if (this.id_post && this.idresposta) {
                    throw new Error('Não pode especificar id_post E idresposta ao mesmo tempo');
                }
            }
        }
    });
};