module.exports = function (sequelize, DataTypes) {
  const resposta = sequelize.define('resposta', {
    idresposta: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    idpost: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'post',
        key: 'idpost'
      }
    },
    autor: {
      type: DataTypes.STRING,
      allowNull: false
    },
    texto: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    datahora: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    },
    idrespostapai: {              
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'resposta',        
        key: 'idresposta'
      }
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    url: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    anexo: {
      type: DataTypes.TEXT,
      allowNull: true
    }
  }, {
    tableName: 'resposta',
    schema: 'public',
    timestamps: false
  });

  // Associação para auto-relacionamento (respostaPai)
  resposta.associate = function(models) {
    resposta.belongsTo(models.resposta, {
      foreignKey: 'idrespostapai',
      as: 'respostaPai',  // nome do alias para a resposta pai
    });
    resposta.belongsTo(models.utilizador, {
      foreignKey: 'idutilizador',
      as: 'autorUser', // <-- alias para o join
    });
  };

  return resposta;
};