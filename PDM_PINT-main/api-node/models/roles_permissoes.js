const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  const RolePermissao = sequelize.define('roles_permissoes', {
    idrole_permissao: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    role: {
      type: DataTypes.STRING(20),
      allowNull: false,
      validate: {
        isIn: [['administrador', 'formador', 'formando']]
      }
    },
    idpermissao: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'permissoes',
        key: 'idpermissao'
      },
      onDelete: 'CASCADE',
      onUpdate: 'NO ACTION'
    },
    datacriacao: {
      type: DataTypes.DATE,
      allowNull: true,
      defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
    },
    dataatualizacao: {
      type: DataTypes.DATE,
      allowNull: true,
      defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
    }
  }, {
    sequelize,
    tableName: 'roles_permissoes',
    schema: 'public',
    timestamps: false,
    indexes: [
      {
        name: 'roles_permissoes_pkey',
        unique: true,
        fields: ['idrole_permissao']
      },
      {
        name: 'uk_role_permissao',
        unique: true,
        fields: ['role', 'idpermissao']
      },
      {
        name: 'idx_roles_permissoes_role',
        fields: ['role']
      }
    ]
  });

  RolePermissao.associate = function(models) {
    // Cada RolePermissao pertence a uma única Permissao
    RolePermissao.belongsTo(models.permissoes, {
      foreignKey: 'idpermissao',
      as: 'permissao'
    });
  };

  return RolePermissao;
};
