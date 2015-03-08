require '05_my_bonus'

describe 'Bonus' do
  before(:each) { DBConnection.reset }
  after(:each) { DBConnection.reset }

  before(:all) do
    class Cat < SQLObject
      belongs_to :human, foreign_key: :owner_id
      has_many :cat_toys

      finalize!
    end

    class Human < SQLObject
      self.table_name = 'humans'

      has_many :cats, foreign_key: :owner_id
      has_many_through :cat_toys, :cats, :cat_toys
      belongs_to :house

      finalize!
    end

    class House < SQLObject
      has_many :humans

      finalize!
    end

    class CatToy < SQLObject
      belongs_to :cat

      finalize!
    end
  end

  describe "#where" do

    let(:matt) { Human.find(2) }
    let(:human_where) { Human.where(fname: "Matt") }

    it "can select one list" do
      expect(human_where).to be_instance_of(Relation)
      expect(human_where.all[0].fname).to eq("Matt")
    end

    it "can chain multiple wheres" do
      expect(human_where.where(house_id: 3).all[0].lname).to eq("Walker")
    end
  end

  describe '#has_many_through' do

    it 'works' do
      devon = Human.find(1)
      cat_toy1 = CatToy.find(1)
      cat_toy2 = CatToy.find(2)
      cat_toy3 = CatToy.find(3)
      expect(devon.cat_toys).to eq([cat_toy1, cat_toy2, cat_toy3])
    end
  end
end
