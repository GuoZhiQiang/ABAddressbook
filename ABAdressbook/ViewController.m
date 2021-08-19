//
//  ViewController.m
//  ABAdressbook
//
//  Created by guo on 2021/8/19.
//

#import "ViewController.h"
#import <Contacts/Contacts.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *_tableView;

@property (nonatomic, strong) CNContactStore *contact;
@property (nonatomic, strong) NSMutableArray *addressArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initData];
    [__tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AddressCell"];
}

- (void)initData {
    
    _addressArray = [NSMutableArray new];
    
    CNContactStore *contact = [CNContactStore new];
    self.contact = contact;
    
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (CNAuthorizationStatusAuthorized == status) {
        
        [self loadContacts];
    }
    else if (CNAuthorizationStatusNotDetermined == status) {

        [_contact requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                [self loadContacts];
            }
        }];
    }
    
}

- (void)loadContacts {
    NSArray *fetchKeys = @[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName],CNContactPhoneNumbersKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:fetchKeys];
    
    NSMutableArray *addArr = [NSMutableArray new];
    [_contact enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        
        // 获取联系人全名
        NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
        if (name.length == 0) {
            NSLog(@"-------");
            NSLog(@"number for null name: %@", contact.phoneNumbers);
        }
        else {
            [addArr addObject:name];
            NSLog(@"identifier ====== %@, name ==== %@", contact.identifier, name);
        }
    }];
    
    NSLog(@"++++++++++");
    NSArray *arr = [addArr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 localizedCompare:obj2];
    }];
    
    [self.addressArray addObjectsFromArray:arr];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self._tableView reloadData];
    });
}

- (NSArray *)queryContactWithName:(NSString *)name{

    //检索条件
    NSPredicate *predicate = [CNContact predicateForContactsMatchingName:name];

    //过滤的条件，也可以过滤时候格式化
    
    NSArray *keysToFetch = @[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName],CNContactPhoneNumbersKey];

    NSArray *contact = [_contact unifiedContactsMatchingPredicate:predicate keysToFetch:keysToFetch error:nil];
    //可能会碰到这种情况：通过上面的 predicate 获取的数据是空的。
    //TODO:
    //通过 unifiedContactWithIdentifier 这个方法能获取到数据,后面有空了换成这个
    //[_contact unifiedContactWithIdentifier:@"" keysToFetch:keysToFetch error:nil];
    
    return contact;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (editingStyle ==UITableViewCellEditingStyleDelete) {
        
        NSString *name = [_addressArray objectAtIndex:indexPath.row];
        
        NSArray *contacts = [self queryContactWithName:name];
        CNContact *contact = contacts.firstObject;
        if (contact) {
            CNMutableContact *mutableContact = (CNMutableContact *)[contact mutableCopy];
            
            CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
            [saveRequest deleteContact:mutableContact];
            
            [self.contact executeSaveRequest:saveRequest error:nil];
            
            [_addressArray removeObjectAtIndex:indexPath.row];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [tableView reloadData];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _addressArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddressCell"];
    }
    
    cell.textLabel.text = [_addressArray objectAtIndex:indexPath.row];
    
    return cell;
}


@end
