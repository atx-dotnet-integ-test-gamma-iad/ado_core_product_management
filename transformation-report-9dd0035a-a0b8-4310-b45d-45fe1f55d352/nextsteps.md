# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

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

Review the output for any warnings about deprecated packages or version conflicts that may not surface as build errors but could cause runtime issues.

## 3. Build the Solution

Perform a clean build to confirm there are no errors:

```bash
dotnet clean
dotnet build
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers, as these can indicate potential runtime problems.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected after migration:

```bash
dotnet test
```

Review test output carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs that were available in .NET Framework may have different behavior or reduced functionality in cross-platform .NET. Review the code for usage of the following:

- `System.Data` and ADO.NET provider-specific classes, since `AdoCore` suggests database interaction
- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)
- Windows-specific registry or COM interop calls
- `AppDomain` usage that may behave differently

You can use the .NET Upgrade Assistant compatibility analyzer or the [.NET API compatibility site](https://apisof.net) to cross-reference any suspect APIs.

## 6. Validate Runtime Behavior

Run the application against a representative set of inputs or scenarios, particularly those involving database connectivity, since ADO.NET provider behavior (connection strings, driver availability) can differ across platforms.

Confirm that the correct database drivers or providers are referenced as NuGet packages rather than relying on system-installed components, for example:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages that only target `net45` or `netstandard1.x` may function but could produce compatibility warnings. Where possible, update packages to their latest stable versions that explicitly support your target TFM.

```bash
dotnet list package --outdated
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish -c Release -r win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) if deploying to a non-Windows environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.