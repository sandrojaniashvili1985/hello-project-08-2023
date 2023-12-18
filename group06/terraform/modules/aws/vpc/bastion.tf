## Data ##
data "aws_ami" "ubuntu_bionic" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}


## EC2 ##
resource "aws_key_pair" "bastion" {
  count = var.create_bastion ? 1 : 0

  key_name   = "${var.name}-bastion"
  public_key = var.public_key
}

resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0

  ami           = data.aws_ami.ubuntu_bionic.id
  instance_type = "t3a.nano"
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = aws_key_pair.bastion[0].key_name

  vpc_security_group_ids = [module.bastion_sg.this_security_group_id]

  tags = merge(
    {
      Name      = "${var.name}-bastion"
      Component = "Bastion"
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

resource "aws_eip" "bastion" {
  count = var.create_bastion ? 1 : 0

  vpc  = true
  tags = merge(
    {
      Name      = "${var.name}-bastion"
      Component = "Bastion"
    },
    var.tags
  )
}

resource "aws_eip_association" "bastion" {
  count = var.create_bastion ? 1 : 0

  instance_id   = aws_instance.bastion[0].id
  allocation_id = aws_eip.bastion[0].id
}
