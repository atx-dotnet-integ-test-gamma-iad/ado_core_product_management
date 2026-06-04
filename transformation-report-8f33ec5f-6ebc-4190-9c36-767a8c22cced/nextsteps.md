# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or version conflicts. If any packages were previously targeting .NET Framework, check their NuGet pages to confirm they support the target cross-platform .NET version.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET.

## 5. Check for Platform-Specific API Usage

Cross-platform .NET does not support certain .NET Framework APIs. Use the .NET Upgrade Assistant or the compatibility analyzer to identify any remaining platform-specific calls. You can add the compatibility analyzer via:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, review the [.NET Framework compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/porting/net-framework-tech-unavailable) for APIs that are unavailable or behave differently.

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows manually or through integration tests. Pay particular attention to:

- File system path handling, as path separators differ between Windows and Unix-based systems.
- Any use of the Windows Registry, COM interop, or WCF, which have limited or no support on non-Windows platforms.
- Configuration file handling, particularly if the project previously relied on `App.config` or `Web.config`.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier for your target platform, such as `linux-x64` or `osx-x64`. Review the contents of the publish output folder to confirm all required files are present before deploying.