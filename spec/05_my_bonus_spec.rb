require '05_my_bonus'

describe 'Bonus' do
  before(:each) { DBConnection.reset }
  after(:each) { DBConnection.reset }

  before(:all) do
    class Cat < SQLObject
      belongs_to :human, foreign_key: :owner_id

      finalize!
    end

    class Human < SQLObject
      self.table_name = 'humans'

      has_many :cats, foreign_key: :owner_id
      belongs_to :house

      finalize!
    end

    class House < SQLObject
      has_many :humans

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
end
