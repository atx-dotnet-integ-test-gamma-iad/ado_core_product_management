# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that may have been suppressed in Debug mode:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or platform compatibility.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify that behavior has not changed during the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usage of APIs such as:

- `System.Windows.Forms`
- `System.Web`
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls targeting Windows-only libraries

## 6. Run the Application

Execute the application directly to confirm it runs as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, write a small integration test or console harness to exercise its public API.

## 7. Review NuGet Package Compatibility

Open the project file and review each `<PackageReference>`. For any packages that were carried over from the legacy project, verify they have versions compatible with the new TFM. Check [nuget.org](https://www.nuget.org) for updated versions if necessary.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64, for example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

The output will be placed in the `bin/Release/<tfm>/publish/` directory. Verify the contents before distributing.