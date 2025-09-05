const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  const Permissao = sequelize.define('permissoes', {
    id: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    nome: {
      type: DataTypes.STRING,
      allowNull: false
    },
    descricao: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    categoria: {
      type: DataTypes.STRING,
      allowNull: true
    },
    ativo: {
      type: DataTypes.BOOLEAN,
      allowNull: true
    },
    datacriacao: {
      type: DataTypes.DATE,
      allowNull: true
    },
    dataatualizacao: {
      type: DataTypes.DATE,
      allowNull: true
    },
    ligado: {
      type: DataTypes.BOOLEAN,
      allowNull: true
    }
  }, {
    sequelize,
    tableName: 'permissoes',
    schema: 'public',
    timestamps: false
  });

  Permissao.associate = function(models) {
    // Uma permissão pode estar atribuída a vários roles
    Permissao.hasMany(models.roles_permissoes, {
      foreignKey: 'id_permissao',
      as: 'rolesPermissoes'
    });
  };

  return Permissao;
};
