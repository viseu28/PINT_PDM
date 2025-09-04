const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('sincronos', {
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    for_idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    idcategoria: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    titulo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    descricao: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    tema: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    data_inicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    data_fim: {
      type: DataTypes.DATE,
      allowNull: false
    },
    tipo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    estado: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    },
    imgcurso: {
      type: DataTypes.BLOB,
      allowNull: false
    },
    avaliacao: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    dificuldade: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    pontos: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idsincrono: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    duracao: {
      type: DataTypes.DATE,
      allowNull: false
    },
    vagas: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'sincronos',
    schema: 'public',
    timestamps: false
  });
};
