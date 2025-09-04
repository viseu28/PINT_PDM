const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  const utilizador = sequelize.define('utilizador', {
    idutilizador: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    nome: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    email: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    palavrapasse: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    tipo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    datanascimento: {
      type: DataTypes.DATEONLY,
      allowNull: false
    },
    telemovel: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    morada: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    codigopostal: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    ultimoacesso: {
      type: DataTypes.DATE,
      allowNull: false
    },
    pontos: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    cidade: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    pais: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    estado: {
      type: DataTypes.TEXT,
      allowNull: true,
      defaultValue: "ativo"
    },
    temquealterarpassword: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true
    }
  }, {
    sequelize,
    tableName: 'utilizador',
    schema: 'public',
    timestamps: false
  });

  utilizador.associate = function(models) {
    utilizador.hasMany(models.post, { foreignKey: 'idutilizador', as: 'posts' });
  };

  return utilizador;
};